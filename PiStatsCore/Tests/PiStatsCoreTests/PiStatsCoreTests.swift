import XCTest
@testable import PiStatsCore

final class PiStatsCoreTests: XCTestCase {
    func testExample() throws {
        // XCTest Documentation
        
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
    }
}

extension Summary {
    static func mockSummary() -> Summary {
        return Summary(
            domainsBeingBlocked: 100,
            dnsQueriesToday: 500,
            adsBlockedToday: 50,
            adsPercentageToday: 10.5,
            uniqueDomains: 300,
            queriesForwarded: 200,
            queriesCached: 100,
            clientsEverSeen: 1000,
            uniqueClients: 800,
            dnsQueriesAllTypes: 1000,
            replyNODATA: 20,
            replyNXDOMAIN: 30,
            replyCNAME: 40,
            replyIP: 50,
            privacyLevel: 2,
            status: "Active",
            gravityLastUpdated: GravityLastUpdated(
                fileExists: true,
                absolute: 123456,
                relative: Relative(days: 1, hours: 2, minutes: 30)
            )
        )
    }
}
