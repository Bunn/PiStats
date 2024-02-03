//
//  V5RemoteTests.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation
import XCTest

@testable import PiStatsCore

final class V5RemoteTests: XCTestCase {
    var host: String!
    var token: String!
    var serverSettings: ServerSettings!
    var credentials: Credentials!

    override func setUp() {
        super.setUp()
        loadConfigValues()

        serverSettings = ServerSettings(version: .v5, host: host)
        credentials = Credentials(apiToken: token)
    }

    override func tearDown() {
        super.tearDown()
        host = nil
        token = nil
        serverSettings = nil
        credentials = nil
    }

    func testRemoteV5Summary_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSummary()
        print("--------\nV5 SUMMARY DATA -> \(String(describing: pihole.summary))\n--------\n")
    }

    func testRemoteV5Status_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateStatus()
        print("--------\nV5 STATUS -> \(String(describing: pihole.status))\n--------\n")
    }

    func testRemoteV5SetDisableStatus_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.setStatus(.disabled)
        print("--------\nSENSOR DATA -> \(pihole.status)\n--------\n")
    }

    func testRemoteV5SetEnableStatus_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.setStatus(.enabled)
        print("--------\nSENSOR DATA -> \(pihole.status)\n--------\n")
    }

    func loadConfigValues() {
        guard let url = Bundle.module.url(forResource: "ServerConfig", withExtension: "plist") else {
            fatalError("ServerConfig.plist not found")
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]

            if let dict = plist["v5"] as? [String: String] {
                host = dict["host"]
                token = dict["token"]
            }

        } catch {
            fatalError("Error reading Config.plist: \(error)")
        }
    }

}
