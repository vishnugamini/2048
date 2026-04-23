import Combine
import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    enum OverlayState: Identifiable, Equatable {
        case victory
        case gameOver

        var id: String {
            switch self {
            case .victory: return "victory"
            case .gameOver: return "gameOver"
            }
        }
    }

    struct HintState: Equatable {
        let direction: MoveDirection
        let predictedScoreGain: Int
        let emptyCellCount: Int
    }

    struct MovePresentation: Identifiable, Equatable {
        let id: Int
        let startBoard: BoardState
        let result: MoveResult
        let scoreBeforeMove: Int
        let reducedMotion: Bool
    }

    private struct GameSnapshot: Equatable {
        let board: BoardState
        let score: Int
        let status: GameStatus
        let hasPresentedWin: Bool
        let hasRecordedCompletion: Bool
    }

    @Published private(set) var board: BoardState
    @Published private(set) var score: Int
    @Published private(set) var bestScore: Int
    @Published private(set) var stats: PlayerStats
    @Published var settings: AppSettings
    @Published var overlayState: OverlayState?
    @Published var showingSettings = false
    @Published var showingStats = false
    @Published var showingHowToPlay = false
    @Published private(set) var hasSavedGame = false
    @Published private(set) var movePresentation: MovePresentation?
    @Published private(set) var hintState: HintState?
    @Published private(set) var achievementBanner: Achievement?

    private let persistence: PersistenceController
    private let haptics: HapticsManager
    private let audio: AudioManager
    private var engine: GameEngine
    private var hasPresentedWin = false
    private var hasRecordedCompletion = false
    private var previousSnapshot: GameSnapshot?
    private var animationSeed = 0
    private var achievementDismissTask: Task<Void, Never>?
    private var inputUnlockTask: Task<Void, Never>?
    private var inputLocked = false

    init(
        persistence: PersistenceController = PersistenceController(),
        haptics: HapticsManager? = nil,
        audio: AudioManager? = nil
    ) {
        self.persistence = persistence
        self.haptics = haptics ?? HapticsManager.shared
        self.audio = audio ?? AudioManager.shared

        var stats = persistence.loadStats()
        let settings = persistence.loadSettings()
        let persistedGame = persistence.loadGame()

        let engine: GameEngine
        if let persistedGame {
            engine = GameEngine(
                board: BoardState(rows: persistedGame.rows),
                score: persistedGame.score,
                status: Self.gameStatus(from: persistedGame.status)
            )
            hasPresentedWin = persistedGame.hasPresentedWin
            hasRecordedCompletion = persistedGame.hasRecordedCompletion
            previousSnapshot = persistedGame.previousSnapshot.map(Self.snapshot(from:))
            hasSavedGame = true
        } else {
            var spawner = RandomTileSpawner()
            engine = GameEngine.newGame(spawner: &spawner)
            hasPresentedWin = false
            hasRecordedCompletion = false
            previousSnapshot = nil
            hasSavedGame = false
        }

        stats.syncAchievements(highestTile: engine.board.maxTile, score: engine.score)

        self.engine = engine
        self.board = engine.board
        self.score = engine.score
        self.bestScore = max(stats.bestScore, engine.score)
        self.stats = stats
        self.settings = settings
        self.showingHowToPlay = !settings.hasSeenOnboarding
    }

    deinit {
        achievementDismissTask?.cancel()
        inputUnlockTask?.cancel()
    }

    func startNewGame() {
        var spawner = RandomTileSpawner()
        let result = engine.restart(using: &spawner)
        board = result.board
        score = result.totalScore
        overlayState = nil
        movePresentation = nil
        hintState = nil
        hasPresentedWin = false
        hasRecordedCompletion = false
        previousSnapshot = nil
        stats.recordNewGame()
        stats.syncAchievements(highestTile: board.maxTile, score: score)
        bestScore = max(bestScore, stats.bestScore)
        hasSavedGame = true
        persistGameState()
        persistence.save(stats: stats)
    }

    func handleSwipe(_ direction: MoveDirection) {
        guard !inputLocked else { return }

        let before = currentSnapshot
        let previousAchievementIDs = Set(stats.unlockedAchievementIDs)
        var spawner = RandomTileSpawner()
        let result = engine.move(direction, using: &spawner)
        guard result.changed else { return }

        board = result.board
        score = result.totalScore
        bestScore = max(bestScore, result.totalScore)
        previousSnapshot = before
        hintState = nil

        animationSeed += 1
        movePresentation = MovePresentation(
            id: animationSeed,
            startBoard: before.board,
            result: result,
            scoreBeforeMove: before.score,
            reducedMotion: settings.reducedMotionEnabled
        )

        stats.recordMove(score: result.totalScore, board: result.board)
        handleCompletionTransitions(for: result)
        emitAchievementBanner(from: previousAchievementIDs)
        persistence.save(stats: stats)
        persistGameState()
        playFeedback(for: result)
        lockInputIfNeeded()
    }

    func undoLastMove() {
        guard let previousSnapshot else { return }

        engine = GameEngine(board: previousSnapshot.board, score: previousSnapshot.score, status: previousSnapshot.status)
        board = previousSnapshot.board
        score = previousSnapshot.score
        overlayState = nil
        hintState = nil
        movePresentation = nil
        hasPresentedWin = previousSnapshot.hasPresentedWin
        hasRecordedCompletion = previousSnapshot.hasRecordedCompletion
        self.previousSnapshot = nil
        stats.recordUndo()
        persistence.save(stats: stats)
        persistGameState()

        if settings.hapticsEnabled {
            haptics.undo()
        }
    }

    func requestHint() {
        let rankedMoves = MoveDirection.allCases.compactMap { direction -> (MoveDirection, MoveResult, Int)? in
            let preview = engine.previewMove(direction)
            guard preview.changed else { return nil }
            let heuristic = (preview.scoreGained * 10_000)
                + (preview.board.emptyPositions.count * 100)
                + preview.board.maxTile
            return (direction, preview, heuristic)
        }

        guard let best = rankedMoves.max(by: { $0.2 < $1.2 }) else {
            hintState = nil
            return
        }

        hintState = HintState(
            direction: best.0,
            predictedScoreGain: best.1.scoreGained,
            emptyCellCount: best.1.board.emptyPositions.count
        )
        stats.recordHint()
        persistence.save(stats: stats)

        if settings.hapticsEnabled {
            haptics.hintPulse()
        }
    }

    func continueGameAvailable() -> Bool {
        hasSavedGame
    }

    func abandonCurrentGame() {
        overlayState = nil
        hintState = nil
        persistGameState()
    }

    func dismissOverlay() {
        overlayState = nil
    }

    func continueAfterVictory() {
        overlayState = nil
    }

    func markOnboardingSeen() {
        settings.hasSeenOnboarding = true
        saveSettings()
        showingHowToPlay = false
    }

    func saveSettings() {
        persistence.save(settings: settings)
    }

    var canUndo: Bool {
        previousSnapshot != nil
    }

    var highestTile: Int {
        max(stats.highestTile, board.maxTile)
    }

    var unlockedAchievements: [Achievement] {
        stats.achievementProgress
    }

    var gamesWon: Int {
        stats.gamesWon
    }

    var winRate: Double {
        guard stats.gamesPlayed > 0 else { return 0 }
        return Double(stats.gamesWon) / Double(stats.gamesPlayed)
    }

    var sessionSummaryTitle: String {
        if hasPresentedWin {
            return "Crown Jewel"
        }
        return "Stay Sharp"
    }

    var sessionSummarySubtitle: String {
        if hasPresentedWin {
            return "You hit 2048. Keep pushing for a bigger run or bank the momentum and restart."
        }

        if let hintState {
            return "Hint: swipe \(hintState.direction.label.lowercased()) for +\(hintState.predictedScoreGain) and \(hintState.emptyCellCount) open spaces."
        }

        return "Smooth chains and keep the center open so your biggest tile has room to breathe."
    }

    private var currentSnapshot: GameSnapshot {
        GameSnapshot(
            board: board,
            score: score,
            status: engine.status,
            hasPresentedWin: hasPresentedWin,
            hasRecordedCompletion: hasRecordedCompletion
        )
    }

    private func lockInputIfNeeded() {
        inputUnlockTask?.cancel()

        guard !settings.reducedMotionEnabled else {
            inputLocked = false
            return
        }

        inputLocked = true
        inputUnlockTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(240))
            inputLocked = false
        }
    }

    private func handleCompletionTransitions(for result: MoveResult) {
        if result.status == .won, !hasPresentedWin {
            hasPresentedWin = true
            overlayState = .victory
            if !hasRecordedCompletion {
                stats.recordGameFinished(score: result.totalScore, board: result.board, didWin: true)
                hasRecordedCompletion = true
            }
        } else if result.status == .lost {
            overlayState = .gameOver
            if !hasRecordedCompletion {
                stats.recordGameFinished(score: result.totalScore, board: result.board, didWin: false)
                hasRecordedCompletion = true
            }
        }

        bestScore = max(bestScore, stats.bestScore)
    }

    private func playFeedback(for result: MoveResult) {
        if settings.hapticsEnabled {
            haptics.moveAccepted()
            if !result.mergeEvents.isEmpty {
                haptics.mergeHighlight()
            }
        }

        if !result.mergeEvents.isEmpty {
            audio.play(named: "merge", enabled: settings.soundEnabled)
        } else {
            audio.play(named: "move", enabled: settings.soundEnabled)
        }

        if overlayState == .victory {
            if settings.hapticsEnabled {
                haptics.didWin()
            }
            audio.play(named: "victory", enabled: settings.soundEnabled)
        } else if overlayState == .gameOver {
            if settings.hapticsEnabled {
                haptics.didLose()
            }
            audio.play(named: "loss", enabled: settings.soundEnabled)
        }
    }

    private func emitAchievementBanner(from previousAchievementIDs: Set<String>) {
        let unlockedNow = stats.achievementProgress
        guard let newest = unlockedNow.first(where: { !previousAchievementIDs.contains($0.id) }) else {
            return
        }

        achievementDismissTask?.cancel()
        achievementBanner = newest
        if settings.hapticsEnabled {
            haptics.achievement()
        }

        achievementDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                achievementBanner = nil
            }
        }
    }

    private func persistGameState() {
        let persisted = PersistedGame(
            rows: board.rows,
            score: score,
            status: Self.persistedStatus(from: engine.status),
            hasPresentedWin: hasPresentedWin,
            hasRecordedCompletion: hasRecordedCompletion,
            previousSnapshot: previousSnapshot.map(Self.persistedSnapshot(from:))
        )
        persistence.save(game: persisted)
        hasSavedGame = true
    }

    private static func persistedSnapshot(from snapshot: GameSnapshot) -> PersistedSnapshot {
        PersistedSnapshot(
            rows: snapshot.board.rows,
            score: snapshot.score,
            status: persistedStatus(from: snapshot.status),
            hasPresentedWin: snapshot.hasPresentedWin,
            hasRecordedCompletion: snapshot.hasRecordedCompletion
        )
    }

    private static func snapshot(from snapshot: PersistedSnapshot) -> GameSnapshot {
        GameSnapshot(
            board: BoardState(rows: snapshot.rows),
            score: snapshot.score,
            status: gameStatus(from: snapshot.status),
            hasPresentedWin: snapshot.hasPresentedWin,
            hasRecordedCompletion: snapshot.hasRecordedCompletion
        )
    }

    private static func persistedStatus(from status: GameStatus) -> PersistedGame.PersistedStatus {
        switch status {
        case .playing: return .playing
        case .won: return .won
        case .lost: return .lost
        }
    }

    private static func gameStatus(from status: PersistedGame.PersistedStatus) -> GameStatus {
        switch status {
        case .playing: return .playing
        case .won: return .won
        case .lost: return .lost
        }
    }
}

extension MoveDirection {
    var label: String {
        switch self {
        case .up: return "Up"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}
