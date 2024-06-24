//
//  Pihole+StorageData.swift
//  PiStats
//
//  Created by Fernando Bunn on 6/24/24.
//

import Foundation
import PiStatsCore
import PiholeStorage

extension Pihole: StorageData {
    public var data: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let encodedData = try encoder.encode(serverSettings)
            return encodedData
        } catch {
            fatalError("Failed to encode Pihole object: \(error)")
        }
    }

    public var secret: Data {
        get {
            return credentials.secret.data(using: .utf8)!
        }
        set(newValue) {
            credentials = Credentials(secret: String(data: newValue, encoding: .utf8)!)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(serverSettings, forKey: .serverSettings)
        try container.encode(credentials, forKey: .credentials)
        try container.encode(name, forKey: .name)
        try container.encode(id, forKey: .id)
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serverSettings = try container.decode(ServerSettings.self, forKey: .serverSettings)
        let credentials = try container.decode(Credentials.self, forKey: .credentials)
        let name = try container.decode(String.self, forKey: .name)
        self.init(serverSettings: serverSettings, credentials: credentials, name: name)
    }

    private enum CodingKeys: String, CodingKey {
        case serverSettings
        case credentials
        case name
        case id
    }
}
