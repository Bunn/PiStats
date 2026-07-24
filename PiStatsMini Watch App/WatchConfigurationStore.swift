import Foundation
import PiStatsCore

nonisolated struct WatchConfigurationStore {
    private static let storageKey = "watchPiholeConfigurations"

    private let defaults: UserDefaults
    private let credentials: WatchCredentialStore

    init(
        defaults: UserDefaults = .standard,
        credentials: WatchCredentialStore = WatchCredentialStore()
    ) {
        self.defaults = defaults
        self.credentials = credentials
    }

    func load() -> [Pihole] {
        guard let data = defaults.data(forKey: Self.storageKey),
              let stored = try? JSONDecoder().decode([StoredConfiguration].self, from: data) else {
            return []
        }

        return stored.map { configuration in
            Pihole(
                name: configuration.name,
                address: configuration.address,
                port: configuration.port,
                secure: configuration.secure,
                password: credentials.password(for: configuration.uuid),
                systemMetricsEnabled: configuration.systemMetricsEnabled,
                uuid: configuration.uuid
            )
        }
    }

    func save(_ piholes: [Pihole]) throws {
        let previousIDs = Set(load().map(\.uuid))
        let currentIDs = Set(piholes.map(\.uuid))

        for pihole in piholes {
            if let password = pihole.password {
                credentials.save(password, for: pihole.uuid)
            }
        }

        for removedID in previousIDs.subtracting(currentIDs) {
            credentials.removePassword(for: removedID)
        }

        let data = try JSONEncoder().encode(piholes.map(StoredConfiguration.init))
        defaults.set(data, forKey: Self.storageKey)
    }

    private nonisolated struct StoredConfiguration: Codable {
        let uuid: UUID
        let name: String
        let address: String
        let port: Int
        let secure: Bool
        let systemMetricsEnabled: Bool

        init(_ pihole: Pihole) {
            uuid = pihole.uuid
            name = pihole.name
            address = pihole.address
            port = pihole.port
            secure = pihole.secure
            systemMetricsEnabled = pihole.systemMetricsEnabled
        }
    }
}
