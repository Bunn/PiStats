//
//  V5ServiceTests.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import XCTest
@testable import PiStatsCore

class V5ServiceTests: XCTestCase {
    private var service: PiholeV5Service!
    private var serverSettings: ServerSettings!
    private var credentials: Credentials!
    
    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)
        
        service = PiholeV5Service(session: session)
        
        serverSettings = ServerSettings(version: .v5, host: "127.0.0.1", requestProtocol: .http)
        credentials = Credentials(apiToken: "batata")
    }
    
    override func tearDown() {
        super.tearDown()
        
        service = nil
        serverSettings = nil
        credentials = nil
    }
    
    func testFetchSummary_WithValidCredentials_ReturnsSummary() async throws {
        struct ExpectedSummary {
            static let totalQueries = 123
            static let queriesBlocked = 456
            static let percentBlocked = 1.30
            static let domainsOnList = 56
            static let activeClients = 5093
        }
        
        let mockedData = JSONMock.summaryV5JSON(totalQueries: "\(ExpectedSummary.totalQueries)",
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
}
