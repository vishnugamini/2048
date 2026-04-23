import SwiftUI
import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()

    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let success = UINotificationFeedbackGenerator()
    private let warning = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        soft.prepare()
        rigid.prepare()
        light.prepare()
        success.prepare()
        warning.prepare()
        selection.prepare()
    }

    func moveAccepted() {
        soft.impactOccurred(intensity: 0.8)
    }

    func mergeHighlight() {
        rigid.impactOccurred(intensity: 1.0)
    }

    func undo() {
        light.impactOccurred(intensity: 0.7)
    }

    func hintPulse() {
        selection.selectionChanged()
    }

    func achievement() {
        success.notificationOccurred(.success)
    }

    func didWin() {
        success.notificationOccurred(.success)
    }

    func didLose() {
        warning.notificationOccurred(.warning)
    }
}
