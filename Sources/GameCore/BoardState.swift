import Foundation

public struct BoardState: Equatable, Sendable {
    public static let dimension = 4

    private var storage: [Int]

    public init(storage: [Int]) {
        precondition(storage.count == Self.dimension * Self.dimension, "Board must contain exactly 16 values.")
        self.storage = storage
    }

    public init(rows: [[Int]]) {
        precondition(rows.count == Self.dimension, "Board must contain 4 rows.")
        let flattened = rows.flatMap { row -> [Int] in
            precondition(row.count == Self.dimension, "Each row must contain 4 columns.")
            return row
        }
        self.init(storage: flattened)
    }

    public static let empty = BoardState(storage: Array(repeating: 0, count: BoardState.dimension * BoardState.dimension))

    public var rows: [[Int]] {
        stride(from: 0, to: storage.count, by: Self.dimension).map { startIndex in
            Array(storage[startIndex..<(startIndex + Self.dimension)])
        }
    }

    public var maxTile: Int {
        storage.max() ?? 0
    }

    public var emptyPositions: [BoardPosition] {
        storage.enumerated().compactMap { index, value in
            guard value == 0 else { return nil }
            return BoardPosition(row: index / Self.dimension, column: index % Self.dimension)
        }
    }

    public var hasEmptyCell: Bool {
        storage.contains(0)
    }

    public subscript(row: Int, column: Int) -> Int {
        get {
            storage[(row * Self.dimension) + column]
        }
        set {
            storage[(row * Self.dimension) + column] = newValue
        }
    }

    public func status() -> GameStatus {
        if maxTile >= winningTileValue {
            return .won
        }

        return hasAvailableMoves ? .playing : .lost
    }

    public var hasAvailableMoves: Bool {
        if hasEmptyCell {
            return true
        }

        for row in 0..<Self.dimension {
            for column in 0..<Self.dimension {
                let value = self[row, column]
                if row + 1 < Self.dimension, self[row + 1, column] == value {
                    return true
                }
                if column + 1 < Self.dimension, self[row, column + 1] == value {
                    return true
                }
            }
        }

        return false
    }
}
