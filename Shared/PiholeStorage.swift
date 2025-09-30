//
//  PiholeStorage.swift
//  PiStats
//
//  Created by Fernando Bunn on 23/06/2025.
//

import PiStatsCore
import Foundation
import Security

protocol PiholeStorage {
    func savePihole(_ pihole: Pihole)
    func deletePihole(_ pihole: Pihole)
    func deleteAllPiholes()
    func restorePihole(_ id: UUID) -> Pihole?
    func restoreAllPiholes() -> [Pihole]
}

// MARK: - Legacy Pihole Model for Migration

/// Legacy Pihole model for backwards compatibility with old stored data
private struct LegacyPihole: Codable {
    let id: UUID
    let address: String
    let displayName: String?
    let piMonitorPort: Int?
    let hasPiMonitor: Bool
    let secure: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case displayName
        case piMonitorPort
        case hasPiMonitor
        case secure
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        address = try container.decode(String.self, forKey: .address)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)

        do {
            piMonitorPort = try container.decodeIfPresent(Int.self, forKey: .piMonitorPort)
        } catch {
            piMonitorPort = nil
        }

        do {
            hasPiMonitor = try container.decode(Bool.self, forKey: .hasPiMonitor)
        } catch {
            hasPiMonitor = false
        }

        do {
            secure = try container.decode(Bool.self, forKey: .secure)
        } catch {
            secure = false
        }
    }
}

// MARK: - UserPreferences for Migration

private class UserPreferences {
    private static let didMigrateAppGroupKey = "didMigrateAppGroup"

    var didMigrateAppGroup: Bool {
        get {
            UserDefaults.shared().bool(forKey: Self.didMigrateAppGroupKey)
        }
        set {
            UserDefaults.shared().set(newValue, forKey: Self.didMigrateAppGroupKey)
        }
    }
}

// MARK: - APIToken Helper

private struct APIToken {
    private static let serviceName = "PiHoleStatsService"
    let accountName: String
    private let passwordItem: KeychainPasswordItem

    init(accountName: String) {
        self.accountName = accountName
        #if os(iOS) || os(tvOS) || os(watchOS)
        let accessGroup: String? = AppGroup.name
        #else
        // On macOS, avoid specifying an access group unless entitlements are configured
        let accessGroup: String? = nil
        #endif
        self.passwordItem = KeychainPasswordItem(
            service: Self.serviceName,
            account: accountName,
            accessGroup: accessGroup
        )
        //migratePasswordItemIfNecessary(accountName)
    }

    private func migratePasswordItemIfNecessary(_ accountName: String) {
        guard UserPreferences().didMigrateAppGroup == false else { return }
        let oldPasswordItem = KeychainPasswordItem(
            service: Self.serviceName,
            account: accountName,
            accessGroup: nil
        )

        if let oldPassword = try? oldPasswordItem.readPassword(), !oldPassword.isEmpty {
            // Migrate the old password to the new keychain item
            try? passwordItem.savePassword(oldPassword)
            try? oldPasswordItem.deleteItem()
        }
    }

    var token: String {
        get {
            do {
                return try passwordItem.readPassword()
            } catch {
                return ""
            }
        }
        set {
            try? passwordItem.savePassword(newValue)
        }
    }

    func delete() {
        try? passwordItem.deleteItem()
    }
}

// MARK: - Default Implementation

final class DefaultPiholeStorage: PiholeStorage {
    private static let piHoleListKey = "PiHoleStatsPiHoleList"
    private static let newPiHoleListKey = "PiStatsNewPiHoleList"
    private var hasMigrated = false

    func savePihole(_ pihole: Pihole) {
        // Persist token/password to Keychain, and do not store it in UserDefaults
        var keychain = APIToken(accountName: pihole.uuid.uuidString)
        if let token = pihole.token, !token.isEmpty {
            keychain.token = token
        } else {
            keychain.delete()
        }

        // Store a representation without token
        let persistablePihole = Pihole(
            name: pihole.name,
            address: pihole.address,
            version: pihole.version,
            port: pihole.port,
            token: nil,
            piMonitor: pihole.piMonitor,
            uuid: pihole.uuid
        )

        var piholeList = restoreAllPiholes()

        // Remove existing pihole with same id if it exists
        piholeList.removeAll { $0.uuid == persistablePihole.uuid }

        // Add the new/updated pihole
        piholeList.append(persistablePihole)

        save(piholeList)
    }

    func deletePihole(_ pihole: Pihole) {
        var piholeList = restoreAllPiholes()
        piholeList.removeAll { $0.uuid == pihole.uuid }
        save(piholeList)

        // Delete associated API token if it exists
        if let legacyUUID = extractLegacyUUID(from: pihole) {
            APIToken(accountName: legacyUUID.uuidString).delete()
        }
    }

    func deleteAllPiholes() {
        let allPiholes = restoreAllPiholes()

        // Delete all associated API tokens
        for pihole in allPiholes {
            if let legacyUUID = extractLegacyUUID(from: pihole) {
                APIToken(accountName: legacyUUID.uuidString).delete()
            }
        }

        // Clear the stored pi-hole list
        save([])
    }

    func restorePihole(_ id: UUID) -> Pihole? {
        return restoreAllPiholes().first { $0.uuid == id }
    }

    func restoreAllPiholes() -> [Pihole] {
        // Always check for migration first
        if !hasMigrated {
            migrateIfNeeded()
            hasMigrated = true
        }

        // Try to load from new storage first
        if let newData = UserDefaults.shared().data(forKey: Self.newPiHoleListKey) {
            let decoder = JSONDecoder()
            do {
                let decoded = try decoder.decode([Pihole].self, from: newData)

                // Rehydrate tokens from Keychain and migrate any embedded tokens to Keychain
                let rehydrated: [Pihole] = decoded.map { stored in
                    var apiToken = APIToken(accountName: stored.uuid.uuidString)

                    // If a token was embedded in storage (legacy), migrate it to keychain
                    if let embedded = stored.token, !embedded.isEmpty {
                        apiToken.token = embedded
                    }

                    let keychainValue = apiToken.token
                    let finalToken: String? = keychainValue.isEmpty ? nil : keychainValue

                    return Pihole(
                        name: stored.name,
                        address: stored.address,
                        version: stored.version,
                        port: stored.port,
                        token: finalToken,
                        piMonitor: stored.piMonitor,
                        uuid: stored.uuid
                    )
                }

                return rehydrated
            } catch {
                Log.storage.error("Error decoding new Pihole list: \(String(describing: error), privacy: .public)")
            }
        }

        return []
    }

    private func save(_ piholes: [Pihole]) {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(piholes)
            UserDefaults.shared().set(encoded, forKey: Self.newPiHoleListKey)
        } catch {
            Log.storage.error("Error encoding Pihole list: \(String(describing: error), privacy: .public)")
        }
    }

    private func migrateIfNeeded() {
        // Check if we have old data to migrate
        guard let oldData = UserDefaults.shared().data(forKey: Self.piHoleListKey) else {
            return
        }

        // Check if we already have new data (migration already happened)
        if UserDefaults.shared().data(forKey: Self.newPiHoleListKey) != nil {
            return
        }

        let decoder = JSONDecoder()
        do {
            let legacyPiholes = try decoder.decode([LegacyPihole].self, from: oldData)
            let migratedPiholes = legacyPiholes.compactMap { migrateLegacyPihole($0) }

            if !migratedPiholes.isEmpty {
                save(migratedPiholes)
                Log.storage.info("Successfully migrated \(migratedPiholes.count, privacy: .public) pi-holes from legacy format")

                // Mark migration as complete
                UserPreferences().didMigrateAppGroup = true
            }
        } catch {
            Log.storage.error("Error migrating legacy pi-holes: \(String(describing: error), privacy: .public)")
        }
    }

    private func migrateLegacyPihole(_ legacy: LegacyPihole) -> Pihole? {
        // Extract host and port from legacy address
        let components = legacy.address.components(separatedBy: ":")
        let host = components.first ?? legacy.address
        let port = components.count > 1 ? Int(components[1]) ?? 80 : 80

        // Get API token from keychain using legacy UUID
        let apiToken = APIToken(accountName: legacy.id.uuidString)
        let token = apiToken.token.isEmpty ? nil : apiToken.token

        // Determine name - use displayName if available, otherwise use host
        let name = legacy.displayName?.isEmpty == false ? legacy.displayName! : host

        // Set up PiMonitor if it was enabled
        let piMonitor: PiMonitorEnvironment? = legacy.hasPiMonitor ?
        PiMonitorEnvironment(
            host: host,
            port: legacy.piMonitorPort ?? 8088,
            secure: legacy.secure
        ) : nil

        // Assume v5 for legacy pi-holes (v6 is newer)
        let version: PiholeVersion = .v5

        return Pihole(
            name: name,
            address: host,
            version: version,
            port: port,
            token: token,
            piMonitor: piMonitor,
            uuid: legacy.id
        )
    }

    private func extractLegacyUUID(from pihole: Pihole) -> UUID? {
        // Return the pihole's UUID - this works for both migrated legacy piholes
        // (which preserve their original UUID) and new piholes (which have their own UUID)
        return pihole.uuid
    }
}

// MARK: - Make Pihole Codable

extension Pihole: Codable {
    enum CodingKeys: String, CodingKey {
        case uuid
        case name
        case address
        case token
        case port
        case version
        case piMonitor
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid) ?? UUID()
        let name = try container.decode(String.self, forKey: .name)
        let address = try container.decode(String.self, forKey: .address)
        let token = try container.decodeIfPresent(String.self, forKey: .token)
        let port = try container.decode(Int.self, forKey: .port)
        let version = try container.decode(PiholeVersion.self, forKey: .version)
        let piMonitor = try container.decodeIfPresent(PiMonitorEnvironment.self, forKey: .piMonitor)

        self.init(
            name: name,
            address: address,
            version: version,
            port: port,
            token: token,
            piMonitor: piMonitor,
            uuid: uuid
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uuid, forKey: .uuid)
        try container.encode(name, forKey: .name)
        try container.encode(address, forKey: .address)
        // Do not encode token/password; it is stored in Keychain
        try container.encode(port, forKey: .port)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(piMonitor, forKey: .piMonitor)
    }
}

// MARK: - Make PiMonitorEnvironment Codable

extension PiMonitorEnvironment: Codable {
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case secure
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let host = try container.decode(String.self, forKey: .host)
        let port = try container.decodeIfPresent(Int.self, forKey: .port)
        let secure = try container.decode(Bool.self, forKey: .secure)

        self.init(host: host, port: port, secure: secure)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(host, forKey: .host)
        try container.encodeIfPresent(port, forKey: .port)
        try container.encode(secure, forKey: .secure)
    }
}

// MARK: - Make PiholeVersion Codable

extension PiholeVersion: Codable {
    // Already conforms to Codable via String raw value
}

// MARK: - Global Storage Instance

/// Global PiholeStorage instance for easy access throughout the app
let piholeStorage: PiholeStorage = DefaultPiholeStorage()
