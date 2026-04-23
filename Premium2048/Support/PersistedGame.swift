import Foundation

struct PersistedGame: Codable, Equatable {
    let rows: [[Int]]
    let score: Int
    let status: PersistedStatus
    let hasPresentedWin: Bool

    enum PersistedStatus: String, Codable {
        case playing
        case won
        case lost
    }

    init(rows: [[Int]], score: Int, status: PersistedStatus, hasPresentedWin: Bool) {
        self.rows = rows
        self.score = score
        self.status = status
        self.hasPresentedWin = hasPresentedWin
    }
}
