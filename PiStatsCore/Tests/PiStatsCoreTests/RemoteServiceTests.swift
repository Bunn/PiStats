//
//  RemoteServiceTests.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation
import XCTest

@testable import PiStatsCore

final class RemoteServiceTests: XCTestCase {
    var v5Host: String!
    var v5Token: String!
    var v6Host: String!
    var v6Password: String!

    override func setUp() {
        super.setUp()
        loadConfigValues()
    }

    func loadConfigValues() {
        guard let url = Bundle.module.url(forResource: "ServerConfig", withExtension: "plist") else {
            fatalError("ServerConfig.plist not found")
        }

        do {
            let data = try Data(contentsOf: url)
            let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: Any]

            if let v5Dict = plist["v5"] as? [String: String] {
                v5Host = v5Dict["host"]
                v5Token = v5Dict["token"]
            }

            if let v6Dict = plist["v6"] as? [String: String] {
                v6Host = v6Dict["host"]
                v6Password = v6Dict["password"]
            }
        } catch {
            fatalError("Error reading Config.plist: \(error)")
        }
    }

    func testSummaryV5() async throws {
        let settings = ServerSettings(version: .v5, host: v5Host)
        let credentials = Credentials(apiToken: v5Token)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSummary()
        print("PH \(String(describing: pihole.summary))")
    }

    func testV6Auth() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        let session = try await service.authenticate(serverSettings: settings, credentials: credentials)
        print(session)
    }

    func testSensorData() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSensorData()
        print("--------\nSENSOR DATA \(String(describing: pihole.sensorData))\n--------\n")
    }

    func testSystemInfo() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSystemInfo()
        print("--------\nSYSTEM INFO \(String(describing: pihole.systemInfo))\n--------\n")
    }

    func testV6Summary() async throws {
        let settings = ServerSettings(version: .v5, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        _ = try await service.fetchSummary(serverSettings:settings, credentials: credentials)
    }

    func testSummaryManagerV5() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSummary()
    }

}
