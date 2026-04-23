import Foundation

public protocol TileSpawning {
    mutating func chooseIndex(count: Int) -> Int
    mutating func chooseTileValue() -> Int
}

public struct RandomTileSpawner: TileSpawning {
    public init() {}

    public mutating func chooseIndex(count: Int) -> Int {
        guard count > 0 else { return 0 }
        return Int.random(in: 0..<count)
    }

    public mutating func chooseTileValue() -> Int {
        Int.random(in: 0..<10) == 0 ? 4 : 2
    }
}

public struct GameEngine: Sendable {
    public private(set) var board: BoardState
    public private(set) var score: Int
    public private(set) var status: GameStatus

    public init(board: BoardState = .empty, score: Int = 0, status: GameStatus = .playing) {
        self.board = board
        self.score = score
        self.status = status
    }

    public static func newGame(spawner: inout some TileSpawning) -> GameEngine {
        var engine = GameEngine()
        _ = engine.spawnRandomTile(using: &spawner)
        _ = engine.spawnRandomTile(using: &spawner)
        engine.status = engine.board.status()
        return engine
    }

    @discardableResult
    public mutating func restart(using spawner: inout some TileSpawning) -> MoveResult {
        self = .newGame(spawner: &spawner)
        return MoveResult(
            board: board,
            scoreGained: 0,
            totalScore: score,
            changed: true,
            spawnedTile: nil,
            mergeEvents: [],
            status: status
        )
    }

    public func previewMove(_ direction: MoveDirection) -> MoveResult {
        let computed = Self.computeMove(board: board, direction: direction)
        let nextStatus = computed.changed ? computed.board.status() : status

        return MoveResult(
            board: computed.board,
            scoreGained: computed.scoreGained,
            totalScore: score + computed.scoreGained,
            changed: computed.changed,
            spawnedTile: nil,
            mergeEvents: computed.mergeEvents,
            status: nextStatus
        )
    }

    @discardableResult
    public mutating func move(_ direction: MoveDirection, using spawner: inout some TileSpawning) -> MoveResult {
        let computed = Self.computeMove(board: board, direction: direction)
        guard computed.changed else {
            return MoveResult(
                board: board,
                scoreGained: 0,
                totalScore: score,
                changed: false,
                spawnedTile: nil,
                mergeEvents: [],
                status: status
            )
        }

        board = computed.board
        score += computed.scoreGained
        let spawnedTile = spawnRandomTile(using: &spawner)
        status = board.status()

        return MoveResult(
            board: board,
            scoreGained: computed.scoreGained,
            totalScore: score,
            changed: true,
            spawnedTile: spawnedTile,
            mergeEvents: computed.mergeEvents,
            status: status
        )
    }

    public static func computeMove(board: BoardState, direction: MoveDirection) -> MoveResult {
        var nextBoard = board
        var mergeEvents: [MergeEvent] = []
        var scoreGained = 0
        var changed = false

        for index in 0..<BoardState.dimension {
            let positions = positionsForLine(index: index, direction: direction)
            let originalEntries = positions.map { (position: $0, value: board[$0.row, $0.column]) }
            let processedLine = processLine(entries: originalEntries, destinationPositions: positions)

            scoreGained += processedLine.scoreGained
            mergeEvents.append(contentsOf: processedLine.mergeEvents)
            changed = changed || processedLine.values != originalEntries.map(\.value)

            for (offset, position) in positions.enumerated() {
                nextBoard[position.row, position.column] = processedLine.values[offset]
            }
        }

        return MoveResult(
            board: nextBoard,
            scoreGained: scoreGained,
            totalScore: scoreGained,
            changed: changed,
            spawnedTile: nil,
            mergeEvents: mergeEvents,
            status: changed ? nextBoard.status() : board.status()
        )
    }

    private mutating func spawnRandomTile(using spawner: inout some TileSpawning) -> TileSpawn? {
        let empties = board.emptyPositions
        guard !empties.isEmpty else { return nil }

        let chosenIndex = min(max(spawner.chooseIndex(count: empties.count), 0), empties.count - 1)
        let position = empties[chosenIndex]
        let value = spawner.chooseTileValue()
        board[position.row, position.column] = value
        return TileSpawn(position: position, value: value)
    }

    private static func positionsForLine(index: Int, direction: MoveDirection) -> [BoardPosition] {
        switch direction {
        case .left:
            return (0..<BoardState.dimension).map { BoardPosition(row: index, column: $0) }
        case .right:
            return (0..<BoardState.dimension).reversed().map { BoardPosition(row: index, column: $0) }
        case .up:
            return (0..<BoardState.dimension).map { BoardPosition(row: $0, column: index) }
        case .down:
            return (0..<BoardState.dimension).reversed().map { BoardPosition(row: $0, column: index) }
        }
    }

    private static func processLine(
        entries: [(position: BoardPosition, value: Int)],
        destinationPositions: [BoardPosition]
    ) -> (values: [Int], scoreGained: Int, mergeEvents: [MergeEvent]) {
        let nonZeroEntries = entries.filter { $0.value != 0 }
        var mergedValues: [Int] = []
        var mergeEvents: [MergeEvent] = []
        var scoreGained = 0
        var index = 0

        while index < nonZeroEntries.count {
            let current = nonZeroEntries[index]
            if index + 1 < nonZeroEntries.count, nonZeroEntries[index + 1].value == current.value {
                let next = nonZeroEntries[index + 1]
                let mergedValue = current.value * 2
                let destination = destinationPositions[mergedValues.count]
                mergedValues.append(mergedValue)
                scoreGained += mergedValue
                mergeEvents.append(
                    MergeEvent(
                        value: mergedValue,
                        destination: destination,
                        sources: [current.position, next.position]
                    )
                )
                index += 2
            } else {
                mergedValues.append(current.value)
                index += 1
            }
        }

        if mergedValues.count < BoardState.dimension {
            mergedValues.append(contentsOf: Array(repeating: 0, count: BoardState.dimension - mergedValues.count))
        }

        return (values: mergedValues, scoreGained: scoreGained, mergeEvents: mergeEvents)
    }
}
