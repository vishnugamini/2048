import SwiftUI
import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let success = UINotificationFeedbackGenerator()
    private let warning = UINotificationFeedbackGenerator()

    private init() {
        soft.prepare()
        rigid.prepare()
        success.prepare()
        warning.prepare()
    }

    func moveAccepted() {
        soft.impactOccurred(intensity: 0.8)
    }

    func mergeHighlight() {
        rigid.impactOccurred(intensity: 1.0)
    }

    func didWin() {
        success.notificationOccurred(.success)
    }

    func didLose() {
        warning.notificationOccurred(.warning)
    }
}
