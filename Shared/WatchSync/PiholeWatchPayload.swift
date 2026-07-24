import Foundation
import PiStatsCore

nonisolated struct PiholeWatchPayload: Codable, Sendable {
    static let applicationContextKey = "piholeConfigurations"
    static let configurationRequestKey = "requestPiholeConfigurations"

    private let configurations: [Configuration]

    init(piholes: [Pihole]) {
        configurations = piholes.map(Configuration.init)
    }

    var piholes: [Pihole] {
        configurations.map(\.pihole)
    }

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    static func decode(_ data: Data) throws -> PiholeWatchPayload {
        try JSONDecoder().decode(PiholeWatchPayload.self, from: data)
    }

    private nonisolated struct Configuration: Codable, Sendable {
        let uuid: UUID
        let name: String
        let address: String
        let port: Int
        let secure: Bool
        let password: String?
        let systemMetricsEnabled: Bool

        init(_ pihole: Pihole) {
            uuid = pihole.uuid
            name = pihole.name
            address = pihole.address
            port = pihole.port
            secure = pihole.secure
            password = pihole.password
            systemMetricsEnabled = pihole.systemMetricsEnabled
        }

        var pihole: Pihole {
            Pihole(
                name: name,
                address: address,
                port: port,
                secure: secure,
                password: password,
                systemMetricsEnabled: systemMetricsEnabled,
                uuid: uuid
            )
        }
    }
}
