import Foundation

public let winningTileValue = 2048

public enum MoveDirection: CaseIterable, Sendable {
    case up
    case down
    case left
    case right
}

public enum GameStatus: Equatable, Sendable {
    case playing
    case won
    case lost
}

public struct BoardPosition: Equatable, Hashable, Sendable {
    public let row: Int
    public let column: Int

    public init(row: Int, column: Int) {
        self.row = row
        self.column = column
    }
}

public struct TileSpawn: Equatable, Sendable {
    public let position: BoardPosition
    public let value: Int

    public init(position: BoardPosition, value: Int) {
        self.position = position
        self.value = value
    }
}

public struct TileMotion: Equatable, Sendable {
    public let source: BoardPosition
    public let destination: BoardPosition
    public let value: Int
    public let mergedIntoDestination: Bool

    public init(
        source: BoardPosition,
        destination: BoardPosition,
        value: Int,
        mergedIntoDestination: Bool
    ) {
        self.source = source
        self.destination = destination
        self.value = value
        self.mergedIntoDestination = mergedIntoDestination
    }
}

public struct MergeEvent: Equatable, Sendable {
    public let value: Int
    public let destination: BoardPosition
    public let sources: [BoardPosition]

    public init(value: Int, destination: BoardPosition, sources: [BoardPosition]) {
        self.value = value
        self.destination = destination
        self.sources = sources
    }
}

public struct MoveResult: Equatable, Sendable {
    public let board: BoardState
    public let scoreGained: Int
    public let totalScore: Int
    public let changed: Bool
    public let tileMotions: [TileMotion]
    public let spawnedTile: TileSpawn?
    public let mergeEvents: [MergeEvent]
    public let status: GameStatus

    public init(
        board: BoardState,
        scoreGained: Int,
        totalScore: Int,
        changed: Bool,
        tileMotions: [TileMotion],
        spawnedTile: TileSpawn?,
        mergeEvents: [MergeEvent],
        status: GameStatus
    ) {
        self.board = board
        self.scoreGained = scoreGained
        self.totalScore = totalScore
        self.changed = changed
        self.tileMotions = tileMotions
        self.spawnedTile = spawnedTile
        self.mergeEvents = mergeEvents
        self.status = status
    }
}

public struct Achievement: Codable, Equatable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case tile
        case wins
        case streak
        case score
    }

    public let id: String
    public let title: String
    public let detail: String
    public let kind: Kind

    public init(id: String, title: String, detail: String, kind: Kind) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind
    }
}

public enum AchievementCatalog {
    public static let all: [Achievement] = [
        Achievement(id: "tile-128", title: "Heat Check", detail: "Create a 128 tile.", kind: .tile),
        Achievement(id: "tile-512", title: "Halfway Hero", detail: "Create a 512 tile.", kind: .tile),
        Achievement(id: "tile-1024", title: "Four Figures", detail: "Create a 1024 tile.", kind: .tile),
        Achievement(id: "tile-2048", title: "Crown Jewel", detail: "Reach 2048.", kind: .tile),
        Achievement(id: "wins-1", title: "First Victory", detail: "Win your first game.", kind: .wins),
        Achievement(id: "wins-5", title: "Winning Habit", detail: "Win 5 games.", kind: .wins),
        Achievement(id: "streak-3", title: "On Fire", detail: "Win 3 games in a row.", kind: .streak),
        Achievement(id: "score-5000", title: "Score Surge", detail: "Reach 5,000 points in a game.", kind: .score),
    ]

    public static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    public static func achievementsUnlocked(
        by stats: PlayerStats,
        highestTile: Int,
        score: Int
    ) -> [Achievement] {
        var unlocked: [Achievement] = []

        if highestTile >= 128, let achievement = byID["tile-128"] { unlocked.append(achievement) }
        if highestTile >= 512, let achievement = byID["tile-512"] { unlocked.append(achievement) }
        if highestTile >= 1024, let achievement = byID["tile-1024"] { unlocked.append(achievement) }
        if highestTile >= 2048, let achievement = byID["tile-2048"] { unlocked.append(achievement) }
        if stats.gamesWon >= 1, let achievement = byID["wins-1"] { unlocked.append(achievement) }
        if stats.gamesWon >= 5, let achievement = byID["wins-5"] { unlocked.append(achievement) }
        if stats.bestWinStreak >= 3, let achievement = byID["streak-3"] { unlocked.append(achievement) }
        if score >= 5000, let achievement = byID["score-5000"] { unlocked.append(achievement) }

        return unlocked
    }
}

public struct PlayerStats: Codable, Equatable, Sendable {
    public var bestScore: Int
    public var highestTile: Int
    public var gamesPlayed: Int
    public var gamesWon: Int
    public var totalMoves: Int
    public var totalUndos: Int
    public var totalHints: Int
    public var currentWinStreak: Int
    public var bestWinStreak: Int
    public var lastFinishedScore: Int
    public var lastFinishedHighestTile: Int
    public var unlockedAchievementIDs: [String]

    public init(
        bestScore: Int = 0,
        highestTile: Int = 0,
        gamesPlayed: Int = 0,
        gamesWon: Int = 0,
        totalMoves: Int = 0,
        totalUndos: Int = 0,
        totalHints: Int = 0,
        currentWinStreak: Int = 0,
        bestWinStreak: Int = 0,
        lastFinishedScore: Int = 0,
        lastFinishedHighestTile: Int = 0,
        unlockedAchievementIDs: [String] = []
    ) {
        self.bestScore = bestScore
        self.highestTile = highestTile
        self.gamesPlayed = gamesPlayed
        self.gamesWon = gamesWon
        self.totalMoves = totalMoves
        self.totalUndos = totalUndos
        self.totalHints = totalHints
        self.currentWinStreak = currentWinStreak
        self.bestWinStreak = bestWinStreak
        self.lastFinishedScore = lastFinishedScore
        self.lastFinishedHighestTile = lastFinishedHighestTile
        self.unlockedAchievementIDs = unlockedAchievementIDs
    }

    public mutating func recordNewGame() {
        gamesPlayed += 1
    }

    public mutating func recordMove(score: Int, board: BoardState) {
        totalMoves += 1
        bestScore = max(bestScore, score)
        highestTile = max(highestTile, board.maxTile)
        unlockAchievements(highestTile: board.maxTile, score: score)
    }

    public mutating func recordUndo() {
        totalUndos += 1
    }

    public mutating func recordHint() {
        totalHints += 1
    }

    public mutating func recordGameFinished(score: Int, board: BoardState, didWin: Bool) {
        lastFinishedScore = score
        lastFinishedHighestTile = board.maxTile
        bestScore = max(bestScore, score)
        highestTile = max(highestTile, board.maxTile)

        if didWin {
            gamesWon += 1
            currentWinStreak += 1
            bestWinStreak = max(bestWinStreak, currentWinStreak)
        } else {
            currentWinStreak = 0
        }

        unlockAchievements(highestTile: board.maxTile, score: score)
    }

    public mutating func syncAchievements(highestTile: Int, score: Int) {
        unlockAchievements(highestTile: highestTile, score: score)
    }

    public var achievementProgress: [Achievement] {
        unlockedAchievementIDs.compactMap { AchievementCatalog.byID[$0] }
    }

    private mutating func unlockAchievements(highestTile: Int, score: Int) {
        let unlocked = AchievementCatalog.achievementsUnlocked(by: self, highestTile: highestTile, score: score)
        let mergedIDs = Set(unlockedAchievementIDs).union(unlocked.map(\.id))
        unlockedAchievementIDs = AchievementCatalog.all
            .map(\.id)
            .filter { mergedIDs.contains($0) }
    }
}
