//
//  macOSTests.swift
//  macOSTests
//
//  Created by Fernando Bunn on 28/01/2025.
//

import Testing
import Foundation
@testable import macOS
@testable import PiStatsCore

@MainActor
struct macOSTests {

    @Test("Add new pihole saves to storage and keychain")
    func addPihole() throws {
        // Arrange: clear any existing list and keychain for a random UUID
        let storage = DefaultPiholeStorage()
        let uuid = UUID()
        let keychainItem = KeychainPasswordItem(service: "PiHoleStatsService", account: uuid.uuidString, accessGroup: nil)
        try? keychainItem.deleteItem()

        // Start with an empty list
        storage.deleteAllPiholes()

        // Act: save a new pihole with a token
        let p = Pihole(
            name: "Test",
            address: "1.2.3.4",
            version: .v6,
            port: 80,
            token: "secret",
            piMonitor: nil,
            uuid: uuid
        )
        storage.savePihole(p)

        // Assert: storage returns item and token is not persisted in defaults
        let restored = storage.restoreAllPiholes()
        #expect(restored.count == 1)
        #expect(restored.first?.uuid == uuid)
        // token should be rehydrated from keychain
        #expect(restored.first?.token == "secret")
    }

    @Test("Editing existing pihole updates keychain token and fields")
    func editPihole() throws {
        let storage = DefaultPiholeStorage()
        let uuid = UUID()

        // Seed
        storage.deleteAllPiholes()
        storage.savePihole(Pihole(name: "Test", address: "1.2.3.4", version: .v6, port: 80, token: "old", piMonitor: nil, uuid: uuid))

        // Edit: change name and token
        storage.savePihole(Pihole(name: "New Name", address: "1.2.3.4", version: .v6, port: 53, token: "new", piMonitor: nil, uuid: uuid))

        let restored = storage.restoreAllPiholes()
        #expect(restored.count == 1)
        let r = try #require(restored.first)
        #expect(r.name == "New Name")
        #expect(r.port == 53)
        #expect(r.token == "new")

        // And keychain reflects the updated token
        let keychainItem = KeychainPasswordItem(service: "PiHoleStatsService", account: uuid.uuidString, accessGroup: nil)
        let keychainToken = try? keychainItem.readPassword()
        #expect(keychainToken == "new")
    }

    @Test("Deleting pihole removes it and its keychain token")
    func deletePihole() throws {
        let storage = DefaultPiholeStorage()
        let uuid = UUID()

        storage.deleteAllPiholes()
        let p = Pihole(name: "ToDelete", address: "1.2.3.4", version: .v6, port: 80, token: "tok", piMonitor: nil, uuid: uuid)
        storage.savePihole(p)

        // Sanity
        #expect(storage.restoreAllPiholes().isEmpty == false)

        // Delete
        storage.deletePihole(p)

        // Assert list empty and keychain cleared
        #expect(storage.restoreAllPiholes().isEmpty)
        let keychainItem = KeychainPasswordItem(service: "PiHoleStatsService", account: uuid.uuidString, accessGroup: nil)
        let token = try? keychainItem.readPassword()
        #expect(token == nil)
    }
}
