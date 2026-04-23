import Foundation

enum VisualTheme: String, Codable, CaseIterable, Identifiable {
    case arcadePulse
    case sunsetSynth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arcadePulse: return "Arcade Pulse"
        case .sunsetSynth: return "Sunset Synth"
        }
    }
}

struct AppSettings: Codable, Equatable {
    var soundEnabled: Bool = true
    var hapticsEnabled: Bool = true
    var reducedMotionEnabled: Bool = false
    var selectedTheme: VisualTheme = .arcadePulse
    var hasSeenOnboarding: Bool = false
}
