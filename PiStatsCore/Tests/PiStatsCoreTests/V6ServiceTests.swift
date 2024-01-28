//
//  V6ServiceTests.swift
//
//
//  Created by Fernando Bunn on 1/22/24.
//

import XCTest
@testable import PiStatsCore

class V6ServiceTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

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

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolMock.self]
        let session = URLSession(configuration: config)

        let service = PiholeV6Service(session: session)

        let serverSettings = ServerSettings(version: .v6, host: "127.0.0.1", requestProtocol: .http)
        let credentials = Credentials(applicationPassword: "batata")
        credentials.sessionID = Credentials.SessionID(sid: "repolho", csrf: "cenoura")
        let result = try await service.fetchSummary(serverSettings: serverSettings, credentials: credentials)

        XCTAssertEqual(result.totalQueries, ExpectedSummary.totalQueries)
        XCTAssertEqual(result.queriesBlocked, ExpectedSummary.queriesBlocked)
        XCTAssertEqual(result.percentBlocked, ExpectedSummary.percentBlocked)
        XCTAssertEqual(result.domainsOnList, ExpectedSummary.domainsOnList)
        XCTAssertEqual(result.activeClients, ExpectedSummary.activeClients)
    }
}
