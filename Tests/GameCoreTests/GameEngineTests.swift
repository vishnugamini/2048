import XCTest
@testable import GameCore

private struct FixedSpawner: TileSpawning {
    var indices: [Int]
    var values: [Int]

    mutating func chooseIndex(count: Int) -> Int {
        guard !indices.isEmpty else { return 0 }
        return indices.removeFirst()
    }

    mutating func chooseTileValue() -> Int {
        guard !values.isEmpty else { return 2 }
        return values.removeFirst()
    }
}

final class GameEngineTests: XCTestCase {
    func testNewGameSpawnsTwoTiles() {
        var spawner = FixedSpawner(indices: [0, 0], values: [2, 4])
        let engine = GameEngine.newGame(spawner: &spawner)

        XCTAssertEqual(engine.board.rows, [
            [2, 4, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        XCTAssertEqual(engine.score, 0)
        XCTAssertEqual(engine.status, .playing)
    }

    func testSwipeLeftMergesAdjacentTilesOnce() {
        let move = GameEngine.computeMove(
            board: BoardState(rows: [
                [2, 2, 2, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            direction: .left
        )

        XCTAssertEqual(move.board.rows[0], [4, 2, 0, 0])
        XCTAssertEqual(move.scoreGained, 4)
        XCTAssertTrue(move.changed)
        XCTAssertEqual(
            move.tileMotions,
            [
                TileMotion(
                    source: BoardPosition(row: 0, column: 0),
                    destination: BoardPosition(row: 0, column: 0),
                    value: 2,
                    mergedIntoDestination: true
                ),
                TileMotion(
                    source: BoardPosition(row: 0, column: 1),
                    destination: BoardPosition(row: 0, column: 0),
                    value: 2,
                    mergedIntoDestination: true
                ),
                TileMotion(
                    source: BoardPosition(row: 0, column: 2),
                    destination: BoardPosition(row: 0, column: 1),
                    value: 2,
                    mergedIntoDestination: false
                ),
            ]
        )
    }

    func testSwipeLeftMergesTwoPairs() {
        let move = GameEngine.computeMove(
            board: BoardState(rows: [
                [2, 2, 2, 2],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            direction: .left
        )

        XCTAssertEqual(move.board.rows[0], [4, 4, 0, 0])
        XCTAssertEqual(move.scoreGained, 8)
    }

    func testGapCollapseMergesCorrectly() {
        let move = GameEngine.computeMove(
            board: BoardState(rows: [
                [2, 0, 2, 2],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            direction: .left
        )

        XCTAssertEqual(move.board.rows[0], [4, 2, 0, 0])
        XCTAssertEqual(move.scoreGained, 4)
    }

    func testVerticalMoveWorks() {
        let move = GameEngine.computeMove(
            board: BoardState(rows: [
                [2, 0, 0, 0],
                [2, 0, 0, 0],
                [4, 0, 0, 0],
                [4, 0, 0, 0],
            ]),
            direction: .up
        )

        XCTAssertEqual(move.board.rows, [
            [4, 0, 0, 0],
            [8, 0, 0, 0],
            [0, 0, 0, 0],
            [0, 0, 0, 0],
        ])
        XCTAssertEqual(move.scoreGained, 12)
    }

    func testMoveDoesNotSpawnIfBoardDidNotChange() {
        var spawner = FixedSpawner(indices: [0], values: [2])
        var engine = GameEngine(
            board: BoardState(rows: [
                [2, 4, 8, 16],
                [32, 64, 128, 256],
                [2, 4, 8, 16],
                [32, 64, 128, 256],
            ]),
            score: 100,
            status: .lost
        )

        let result = engine.move(.left, using: &spawner)

        XCTAssertFalse(result.changed)
        XCTAssertNil(result.spawnedTile)
        XCTAssertEqual(result.totalScore, 100)
        XCTAssertEqual(result.tileMotions, [])
        XCTAssertEqual(engine.board.rows[0], [2, 4, 8, 16])
    }

    func testMoveSpawnsOnlyInEmptyCells() {
        var spawner = FixedSpawner(indices: [0], values: [4])
        var engine = GameEngine(
            board: BoardState(rows: [
                [2, 2, 4, 8],
                [16, 32, 64, 128],
                [256, 512, 1024, 0],
                [0, 0, 0, 0],
            ]),
            score: 0,
            status: .playing
        )

        let result = engine.move(.left, using: &spawner)

        XCTAssertEqual(result.board.rows, [
            [4, 4, 8, 4],
            [16, 32, 64, 128],
            [256, 512, 1024, 0],
            [0, 0, 0, 0],
        ])
        XCTAssertEqual(result.spawnedTile?.position, BoardPosition(row: 0, column: 3))
        XCTAssertEqual(result.spawnedTile?.value, 4)
    }

    func testPreviewMoveIncludesTravelPathForSimpleSlide() {
        let preview = GameEngine(
            board: BoardState(rows: [
                [0, 2, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            score: 10,
            status: .playing
        ).previewMove(.left)

        XCTAssertEqual(preview.totalScore, 10)
        XCTAssertEqual(preview.board.rows[0], [2, 0, 0, 0])
        XCTAssertEqual(
            preview.tileMotions,
            [
                TileMotion(
                    source: BoardPosition(row: 0, column: 1),
                    destination: BoardPosition(row: 0, column: 0),
                    value: 2,
                    mergedIntoDestination: false
                ),
            ]
        )
    }

    func testWinDetection() {
        let move = GameEngine.computeMove(
            board: BoardState(rows: [
                [1024, 1024, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            direction: .left
        )

        XCTAssertEqual(move.board.rows[0], [2048, 0, 0, 0])
        XCTAssertEqual(move.status, .won)
    }

    func testLossDetection() {
        let board = BoardState(rows: [
            [2, 4, 2, 4],
            [4, 2, 4, 2],
            [2, 4, 2, 4],
            [4, 2, 4, 8],
        ])

        XCTAssertEqual(board.status(), .lost)
        XCTAssertFalse(board.hasAvailableMoves)
    }

    func testPlayerStatsUnlocksAchievementsAndTracksWinState() {
        var stats = PlayerStats()
        stats.recordNewGame()
        stats.recordMove(
            score: 5120,
            board: BoardState(rows: [
                [2048, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ])
        )
        stats.recordGameFinished(
            score: 5120,
            board: BoardState(rows: [
                [2048, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
                [0, 0, 0, 0],
            ]),
            didWin: true
        )

        XCTAssertEqual(stats.gamesPlayed, 1)
        XCTAssertEqual(stats.gamesWon, 1)
        XCTAssertEqual(stats.currentWinStreak, 1)
        XCTAssertTrue(stats.unlockedAchievementIDs.contains("tile-2048"))
        XCTAssertTrue(stats.unlockedAchievementIDs.contains("wins-1"))
        XCTAssertTrue(stats.unlockedAchievementIDs.contains("score-5000"))
    }
}
