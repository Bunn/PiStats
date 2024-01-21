//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation

final class PiholeManager {
    let pihole: Pihole
    let service: PiholeService

    init(pihole: Pihole) {
        self.pihole = pihole

        if pihole.serverSettings.version == .v5 {
            self.service = PiholeV5Service()
        } else {
            self.service = PiholeV6Service()
        }
    }

    public func fetchSummary() async throws {
        try await pihole.summary = service.fetchSummary(pihole.serverSettings, credentials: pihole.credentials)
    }
}
