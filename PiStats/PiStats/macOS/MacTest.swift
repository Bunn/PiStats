//
//  MacTest.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation
import PiStatsCore

struct MacTest {
    static func test() {
        print("BAtata")

        let server = ServerSettings(version: .v5, host: "x", requestProtocol: .http)
        let credentials = Credentials(apiToken: "x")
        let pihole = Pihole(serverSettings: server, credentials: credentials)

        let manager = PiholeManager(pihole: pihole)

        Task {
            try await manager.updateSummary()
            print("P \(manager.pihole.summary)")
        }
    }
}
