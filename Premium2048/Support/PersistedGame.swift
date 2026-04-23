import Foundation

struct PersistedSnapshot: Codable, Equatable {
    let rows: [[Int]]
    let score: Int
    let status: PersistedGame.PersistedStatus
    let hasPresentedWin: Bool
    let hasRecordedCompletion: Bool

    init(
        rows: [[Int]],
        score: Int,
        status: PersistedGame.PersistedStatus,
        hasPresentedWin: Bool,
        hasRecordedCompletion: Bool
    ) {
        self.rows = rows
        self.score = score
        self.status = status
        self.hasPresentedWin = hasPresentedWin
        self.hasRecordedCompletion = hasRecordedCompletion
    }
}

struct PersistedGame: Codable, Equatable {
    let rows: [[Int]]
    let score: Int
    let status: PersistedStatus
    let hasPresentedWin: Bool
    let hasRecordedCompletion: Bool
    let previousSnapshot: PersistedSnapshot?

    enum PersistedStatus: String, Codable {
        case playing
        case won
        case lost
    }

    init(
        rows: [[Int]],
        score: Int,
        status: PersistedStatus,
        hasPresentedWin: Bool,
        hasRecordedCompletion: Bool,
        previousSnapshot: PersistedSnapshot?
    ) {
        self.rows = rows
        self.score = score
        self.status = status
        self.hasPresentedWin = hasPresentedWin
        self.hasRecordedCompletion = hasRecordedCompletion
        self.previousSnapshot = previousSnapshot
    }
}
