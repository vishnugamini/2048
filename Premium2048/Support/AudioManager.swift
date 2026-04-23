import AVFoundation
import Foundation

@MainActor
final class AudioManager {
    static let shared = AudioManager()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    func play(named resource: String, enabled: Bool) {
        guard enabled else { return }
        guard let player = player(for: resource) else { return }
        player.currentTime = 0
        player.play()
    }

    private func player(for resource: String) -> AVAudioPlayer? {
        if let cached = players[resource] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav") else {
            return nil
        }

        let player = try? AVAudioPlayer(contentsOf: url)
        player?.prepareToPlay()
        if let player {
            players[resource] = player
        }
        return player
    }
}
