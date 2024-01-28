//
//  V6ServiceTests.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import XCTest
@testable import PiStatsCore

class V6ServiceTests: XCTestCase {
    private var service: PiholeV6Service!
    private var serverSettings: ServerSettings!
    private var credentials: Credentials!

    override func setUp() {
        super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)

        service = PiholeV6Service(session: session)

        serverSettings = ServerSettings(version: .v6, host: "127.0.0.1", requestProtocol: .http)
        credentials = Credentials(applicationPassword: "batata")
        credentials.sessionID = Credentials.SessionID(sid: "repolho", csrf: "cenoura")
    }

    override func tearDown() {
        super.tearDown()

        service = nil
        serverSettings = nil
        credentials = nil
    }

    //MARK: - Summary

    func testFetchSummary_WithValidCredentials_ReturnsSummary() async throws {
        struct ExpectedSummary {
            static let totalQueries = 123
            static let queriesBlocked = 456
            static let percentBlocked = 1.30
            static let domainsOnList = 56
            static let activeClients = 5093
        }

        let mockedData = JSONMock.summaryV6JSON(totalQueries: "\(ExpectedSummary.totalQueries)",
                                                queriesBlocked: "\(ExpectedSummary.queriesBlocked)",
                                                percentBlocked: "\(ExpectedSummary.percentBlocked)",
                                                domainsOnList: "\(ExpectedSummary.domainsOnList)",
                                                activeClients: "\(ExpectedSummary.activeClients)")

        URLProtocolMock.expectedData = Data(mockedData.utf8)

        let result = try await service.fetchSummary(serverSettings: serverSettings, credentials: credentials)

        XCTAssertEqual(result.totalQueries, ExpectedSummary.totalQueries)
        XCTAssertEqual(result.queriesBlocked, ExpectedSummary.queriesBlocked)
        XCTAssertEqual(result.percentBlocked, ExpectedSummary.percentBlocked)
        XCTAssertEqual(result.domainsOnList, ExpectedSummary.domainsOnList)
        XCTAssertEqual(result.activeClients, ExpectedSummary.activeClients)
    }

    //MARK: - System Info

    func testFetchSystemInfo_WithValidCredentials_ReturnsSystemInfo() async throws {
        struct ExpectedSystemInfo {
            static let uptime = 203
            static let totalRam = 456
            static let freeRam = 432
            static let percentUsedRam = 0.134
            static let totalSwap = 5093
        }

        let mockedData = JSONMock.systemInfo(uptime: "\(ExpectedSystemInfo.uptime)",
                                             totalRam: "\(ExpectedSystemInfo.totalRam)",
                                             freeRam: "\(ExpectedSystemInfo.freeRam)",
                                             percentUsedRam: "\(ExpectedSystemInfo.percentUsedRam)",
                                             totalSwap: "\(ExpectedSystemInfo.totalSwap)")

        URLProtocolMock.expectedData = Data(mockedData.utf8)

        let result = try await service.fetchSystemInfo(serverSettings: serverSettings, credentials: credentials)

        XCTAssertEqual(result.system.uptime, ExpectedSystemInfo.uptime)
        XCTAssertEqual(result.system.memory.ram.total, ExpectedSystemInfo.totalRam)
        XCTAssertEqual(result.system.memory.ram.free, ExpectedSystemInfo.freeRam)
        XCTAssertEqual(result.system.memory.ram.percentUsed, ExpectedSystemInfo.percentUsedRam)
        XCTAssertEqual(result.system.memory.swap.total, ExpectedSystemInfo.totalSwap)
    }
}
