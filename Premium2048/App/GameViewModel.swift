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

    @Published private(set) var board: BoardState
    @Published private(set) var score: Int
    @Published private(set) var bestScore: Int
    @Published private(set) var stats: PlayerStats
    @Published var settings: AppSettings
    @Published var overlayState: OverlayState?
    @Published var showingSettings = false
    @Published var showingStats = false
    @Published private(set) var hasSavedGame = false

    private let persistence: PersistenceController
    private let haptics: HapticsManager
    private let audio: AudioManager
    private var engine: GameEngine
    private var hasPresentedWin = false

    init(
        persistence: PersistenceController = PersistenceController(),
        haptics: HapticsManager? = nil,
        audio: AudioManager? = nil
    ) {
        self.persistence = persistence
        self.haptics = haptics ?? HapticsManager.shared
        self.audio = audio ?? AudioManager.shared

        let stats = persistence.loadStats()
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
            hasSavedGame = true
        } else {
            var spawner = RandomTileSpawner()
            engine = GameEngine.newGame(spawner: &spawner)
            hasPresentedWin = false
            hasSavedGame = false
        }

        self.engine = engine
        self.board = engine.board
        self.score = engine.score
        self.bestScore = stats.bestScore
        self.stats = stats
        self.settings = settings
    }

    func startNewGame() {
        var spawner = RandomTileSpawner()
        let result = engine.restart(using: &spawner)
        board = result.board
        score = result.totalScore
        overlayState = nil
        hasPresentedWin = false
        stats.recordNewGame()
        stats.highestTile = max(stats.highestTile, board.maxTile)
        bestScore = max(bestScore, stats.bestScore)
        hasSavedGame = true
        persistGameState()
        persistence.save(stats: stats)
    }

    func handleSwipe(_ direction: MoveDirection) {
        var spawner = RandomTileSpawner()
        let result = engine.move(direction, using: &spawner)
        guard result.changed else { return }

        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
            board = result.board
            score = result.totalScore
            bestScore = max(bestScore, result.totalScore)
        }

        stats.recordMove(score: result.totalScore, board: result.board)
        persistence.save(stats: stats)
        persistGameState()

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

        if result.status == .won, !hasPresentedWin {
            hasPresentedWin = true
            overlayState = .victory
            if settings.hapticsEnabled {
                haptics.didWin()
            }
            audio.play(named: "victory", enabled: settings.soundEnabled)
        } else if result.status == .lost {
            overlayState = .gameOver
            if settings.hapticsEnabled {
                haptics.didLose()
            }
            audio.play(named: "loss", enabled: settings.soundEnabled)
        }
    }

    func continueGameAvailable() -> Bool {
        hasSavedGame
    }

    func abandonCurrentGame() {
        overlayState = nil
        persistGameState()
    }

    func dismissOverlay() {
        overlayState = nil
    }

    func saveSettings() {
        persistence.save(settings: settings)
    }

    var highestTile: Int {
        max(stats.highestTile, board.maxTile)
    }

    private func persistGameState() {
        let persisted = PersistedGame(
            rows: board.rows,
            score: score,
            status: Self.persistedStatus(from: engine.status),
            hasPresentedWin: hasPresentedWin
        )
        persistence.save(game: persisted)
        hasSavedGame = true
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
