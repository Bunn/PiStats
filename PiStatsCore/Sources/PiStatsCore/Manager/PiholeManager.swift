//
//  PiholeManager.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
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

    public func updateSummary() async throws {
        try await pihole.summary = service.fetchSummary(serverSettings: pihole.serverSettings,
                                                        credentials: pihole.credentials)
    }

    public func updateStatus() async throws {
        try await pihole.status = service.fetchStatus(serverSettings: pihole.serverSettings,
                                                      credentials: pihole.credentials)
    }

    public func updateSystemInfo() async throws {
        try await pihole.systemInfo = service.fetchSystemInfo(serverSettings: pihole.serverSettings,
                                                              credentials: pihole.credentials)
    }

    public func updateSensorData() async throws {
        try await pihole.sensorData = service.fetchSensorData(serverSettings: pihole.serverSettings,
                                                              credentials: pihole.credentials)
    }
    
    public func setStatus(_ status: Pihole.Status) async throws {
        try await service.setStatus(status, timer: nil,
                                    serverSettings: pihole.serverSettings,
                                    credentials: pihole.credentials)
    }
}
