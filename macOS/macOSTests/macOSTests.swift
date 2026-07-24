//
//  macOSTests.swift
//  macOSTests
//
//  Created by Fernando Bunn on 28/01/2025.
//

import Testing
import Foundation
@testable import Pi_Stats
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

        // Act: save a new Pi-hole with a password
        let p = Pihole(
            name: "Test",
            address: "1.2.3.4",
            port: 80,
            password: "secret",
            uuid: uuid
        )
        storage.savePihole(p)

        // Assert: storage returns the item and the password is not persisted in defaults
        let restored = storage.restoreAllPiholes()
        #expect(restored.count == 1)
        #expect(restored.first?.uuid == uuid)
        // The password should be rehydrated from Keychain
        #expect(restored.first?.password == "secret")
    }

    @Test("Editing existing Pi-hole updates Keychain password and fields")
    func editPihole() throws {
        let storage = DefaultPiholeStorage()
        let uuid = UUID()

        // Seed
        storage.deleteAllPiholes()
        storage.savePihole(Pihole(name: "Test", address: "1.2.3.4", port: 80, password: "old", uuid: uuid))

        // Edit: change name and password
        storage.savePihole(Pihole(name: "New Name", address: "1.2.3.4", port: 53, password: "new", uuid: uuid))

        let restored = storage.restoreAllPiholes()
        #expect(restored.count == 1)
        let r = try #require(restored.first)
        #expect(r.name == "New Name")
        #expect(r.port == 53)
        #expect(r.password == "new")

        // And Keychain reflects the updated password
        let keychainItem = KeychainPasswordItem(service: "PiHoleStatsService", account: uuid.uuidString, accessGroup: nil)
        let keychainPassword = try? keychainItem.readPassword()
        #expect(keychainPassword == "new")
    }

    @Test("Deleting Pi-hole removes it and its Keychain password")
    func deletePihole() throws {
        let storage = DefaultPiholeStorage()
        let uuid = UUID()

        storage.deleteAllPiholes()
        let p = Pihole(name: "ToDelete", address: "1.2.3.4", port: 80, password: "secret", uuid: uuid)
        storage.savePihole(p)

        // Sanity
        #expect(storage.restoreAllPiholes().isEmpty == false)

        // Delete
        storage.deletePihole(p)

        // Assert list empty and keychain cleared
        #expect(storage.restoreAllPiholes().isEmpty)
        let keychainItem = KeychainPasswordItem(service: "PiHoleStatsService", account: uuid.uuidString, accessGroup: nil)
        let password = try? keychainItem.readPassword()
        #expect(password == nil)
    }

    @Test("System metrics errors do not replace the primary connection state")
    func systemMetricsErrorDoesNotAffectPiholeStatusAlerts() async {
        let updater = PiholeSummaryDataUpdater(
            pihole: Pihole(
                name: "Test",
                address: "1.2.3.4"
            )
        )

        updater.handleError(PiholeServiceError.cannotParseResponse, context: .fetchingSystemMetrics)

        #expect(updater.summary.hasError == false)
        #expect(updater.summary.currentError == nil)
        #expect(updater.summary.hasPiholeError == false)
    }

    @Test("Pi-hole polling errors mark Pi-hole status as failed")
    func piholePollingErrorAffectsPiholeStatusAlerts() async {
        let updater = PiholeSummaryDataUpdater(
            pihole: Pihole(name: "Test", address: "1.2.3.4")
        )

        updater.handleError(PiholeServiceError.networkError(URLError(.timedOut)), context: .fetchingStatus)
        await Task.yield()

        #expect(updater.summary.hasError)
        #expect(updater.summary.hasPiholeError)
    }
}
