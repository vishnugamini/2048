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
    public let spawnedTile: TileSpawn?
    public let mergeEvents: [MergeEvent]
    public let status: GameStatus

    public init(
        board: BoardState,
        scoreGained: Int,
        totalScore: Int,
        changed: Bool,
        spawnedTile: TileSpawn?,
        mergeEvents: [MergeEvent],
        status: GameStatus
    ) {
        self.board = board
        self.scoreGained = scoreGained
        self.totalScore = totalScore
        self.changed = changed
        self.spawnedTile = spawnedTile
        self.mergeEvents = mergeEvents
        self.status = status
    }
}

public struct PlayerStats: Codable, Equatable, Sendable {
    public var bestScore: Int
    public var highestTile: Int
    public var gamesPlayed: Int
    public var totalMoves: Int

    public init(bestScore: Int = 0, highestTile: Int = 0, gamesPlayed: Int = 0, totalMoves: Int = 0) {
        self.bestScore = bestScore
        self.highestTile = highestTile
        self.gamesPlayed = gamesPlayed
        self.totalMoves = totalMoves
    }

    public mutating func recordNewGame() {
        gamesPlayed += 1
    }

    public mutating func recordMove(score: Int, board: BoardState) {
        totalMoves += 1
        bestScore = max(bestScore, score)
        highestTile = max(highestTile, board.maxTile)
    }
}
