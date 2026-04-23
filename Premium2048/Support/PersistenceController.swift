import Foundation

final class PersistenceController {
    private enum Keys {
        static let stats = "premium2048.stats"
        static let settings = "premium2048.settings"
    }

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadStats() -> PlayerStats {
        guard
            let data = defaults.data(forKey: Keys.stats),
            let stats = try? decoder.decode(PlayerStats.self, from: data)
        else {
            return PlayerStats()
        }

        return stats
    }

    func save(stats: PlayerStats) {
        guard let data = try? encoder.encode(stats) else { return }
        defaults.set(data, forKey: Keys.stats)
    }

    func loadSettings() -> AppSettings {
        guard
            let data = defaults.data(forKey: Keys.settings),
            let settings = try? decoder.decode(AppSettings.self, from: data)
        else {
            return AppSettings()
        }

        return settings
    }

    func save(settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: Keys.settings)
    }
}
