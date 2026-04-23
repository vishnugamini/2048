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

    private let persistence: PersistenceController
    private let haptics: HapticsManager
    private let audio: AudioManager
    private var engine: GameEngine
    private var hasPresentedWin = false

    init(
        persistence: PersistenceController = PersistenceController(),
        haptics: HapticsManager = .shared,
        audio: AudioManager = .shared
    ) {
        self.persistence = persistence
        self.haptics = haptics
        self.audio = audio

        var spawner = RandomTileSpawner()
        let engine = GameEngine.newGame(spawner: &spawner)
        let stats = persistence.loadStats()
        let settings = persistence.loadSettings()

        self.engine = engine
        self.board = engine.board
        self.score = engine.score
        self.bestScore = stats.bestScore
        self.stats = stats
        self.settings = settings

        recordNewGameIfNeeded()
    }

    func restartGame() {
        var spawner = RandomTileSpawner()
        let result = engine.restart(using: &spawner)
        board = result.board
        score = result.totalScore
        overlayState = nil
        hasPresentedWin = false
        recordNewGameIfNeeded()
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

    func dismissOverlay() {
        overlayState = nil
    }

    func saveSettings() {
        persistence.save(settings: settings)
    }

    var highestTile: Int {
        max(stats.highestTile, board.maxTile)
    }

    private func recordNewGameIfNeeded() {
        stats.recordNewGame()
        stats.highestTile = max(stats.highestTile, board.maxTile)
        bestScore = max(bestScore, stats.bestScore)
        persistence.save(stats: stats)
    }
}
