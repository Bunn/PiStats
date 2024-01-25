import XCTest
@testable import PiStatsCore

final class PiStatsCoreTests: XCTestCase {
    let v5Host = ""
    let v5Token = ""

    let v6Host = ""
    let v6Password = ""

    func testSummaryV5() async throws {
        let settings = ServerSettings(version: .v5, host: v5Host)
        let credentials = Credentials(apiToken: v5Token)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.fetchSummary()
        print("PH \(pihole.summary)")
    }

    func testV6Auth() async throws {
        let settings = ServerSettings(version: .v5, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        try await service.authenticate(settings, credentials: credentials)
    }

    func testV6Summary() async throws {
        let settings = ServerSettings(version: .v5, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let service = PiholeV6Service()
        try await service.fetchSummary(settings, credentials: credentials)
    }

    func testSummaryManagerV5() async throws {
        let settings = ServerSettings(version: .v6, host: v6Host)
        let credentials = Credentials(applicationPassword: v6Password)

        let pihole = Pihole(serverSettings: settings, credentials: credentials)
        let manager = PiholeManager(pihole: pihole)
        try await manager.fetchSummary()
        print("PH \(pihole.summary)")
    }

}
