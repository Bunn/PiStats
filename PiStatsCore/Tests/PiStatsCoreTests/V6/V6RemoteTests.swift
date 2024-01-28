//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/28/24.
//

import Foundation
import XCTest
@testable import PiStatsCore

final class V6RemoteTests: XCTestCase {
    var host: String!
    var password: String!
    var serverSettings: ServerSettings!
    var credentials: Credentials!

    override func setUp() {
        super.setUp()
        loadConfigValues()

        serverSettings = ServerSettings(version: .v6, host: host)
        credentials = Credentials(applicationPassword: password)
    }

    override func tearDown() {
        super.tearDown()
        host = nil
        password = nil
        serverSettings = nil
        credentials = nil
    }

    func testRemoteV6Summary_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSummary()
        print("--------\nV6 SUMMARY DATA -> \(String(describing: pihole.summary))\n--------\n")
    }

    func testRemoteAuth_WithValidCredentials() async throws {
        let service = PiholeV6Service()
        _ = try await service.authenticate(serverSettings: serverSettings, credentials: credentials)
    }

    func testRemoteV6SensorData_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSensorData()
        print("--------\nSENSOR DATA -> \(String(describing: pihole.sensorData))\n--------\n")
    }

    func testRemoteV6Status_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateStatus()
        print("--------\nSENSOR DATA -> \(pihole.status)\n--------\n")
    }

    func testRemoteV6SystemInfo_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.updateSystemInfo()
        print("--------\nSYSTEM INFO ->\(String(describing: pihole.systemInfo))\n--------\n")
    }

    func testRemoteV6SetDisableStatus_WithValidFetch() async throws {
        let pihole = Pihole(serverSettings: serverSettings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.setStatus(.disabled)
        print("--------\nSENSOR DATA -> \(pihole.status)\n--------\n")
    }

    func testRemoteV6SetEnableStatus_WithValidFetch() async throws {
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

            if let dict = plist["v6"] as? [String: String] {
                host = dict["host"]
                password = dict["password"]
            }

        } catch {
            fatalError("Error reading Config.plist: \(error)")
        }
    }

}
