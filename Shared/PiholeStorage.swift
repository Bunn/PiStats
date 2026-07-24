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
    let secure: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case address
        case displayName
        case secure
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        address = try container.decode(String.self, forKey: .address)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)

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

// MARK: - Credential Helper

private struct PiholeCredential {
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

    var password: String {
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
        // Persist the password to Keychain, and do not store it in UserDefaults
        var credential = PiholeCredential(accountName: pihole.uuid.uuidString)
        if let password = pihole.password, !password.isEmpty {
            credential.password = password
        } else {
            credential.delete()
        }

        // Store a representation without the password
        let persistablePihole = Pihole(
            name: pihole.name,
            address: pihole.address,
            port: pihole.port,
            secure: pihole.secure,
            password: nil,
            systemMetricsEnabled: pihole.systemMetricsEnabled,
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

        // Delete the associated password if it exists
        PiholeCredential(accountName: pihole.uuid.uuidString).delete()
    }

    func deleteAllPiholes() {
        let allPiholes = restoreAllPiholes()

        // Delete all associated passwords
        for pihole in allPiholes {
            PiholeCredential(accountName: pihole.uuid.uuidString).delete()
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

                // Rehydrate passwords from Keychain and migrate any embedded legacy values
                let rehydrated: [Pihole] = decoded.map { stored in
                    var credential = PiholeCredential(accountName: stored.uuid.uuidString)

                    // Older records could embed the credential in UserDefaults.
                    if let embedded = stored.password, !embedded.isEmpty {
                        credential.password = embedded
                    }

                    let keychainValue = credential.password
                    let password: String? = keychainValue.isEmpty ? nil : keychainValue

                    return Pihole(
                        name: stored.name,
                        address: stored.address,
                        port: stored.port,
                        secure: stored.secure,
                        password: password,
                        systemMetricsEnabled: stored.systemMetricsEnabled,
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

        // Get the credential from Keychain using the legacy UUID.
        let credential = PiholeCredential(accountName: legacy.id.uuidString)
        let password = credential.password.isEmpty ? nil : credential.password

        // Determine name - use displayName if available, otherwise use host
        let name = legacy.displayName?.isEmpty == false ? legacy.displayName! : host

        return Pihole(
            name: name,
            address: host,
            port: port,
            secure: legacy.secure,
            password: password,
            uuid: legacy.id
        )
    }
}

// MARK: - Global Storage Instance

/// Global PiholeStorage instance for easy access throughout the app
let piholeStorage: PiholeStorage = DefaultPiholeStorage()
