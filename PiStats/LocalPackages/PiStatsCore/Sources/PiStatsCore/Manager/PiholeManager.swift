//
//  PiholeManager.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

final public class PiholeManager {
    public let pihole: Pihole
    let service: PiholeService

    public init(pihole: Pihole) {
        self.pihole = pihole

        if pihole.serverSettings.version == .v5 {
            self.service = PiholeV5Service()
        } else {
            self.service = PiholeV6Service()
        }
    }

    public func updateSummary() async throws {
        pihole.summary = try await service.fetchSummary(serverSettings: pihole.serverSettings,
                                                        credentials: pihole.credentials)
    }

    public func updateStatus() async throws {
        pihole.status = try await service.fetchStatus(serverSettings: pihole.serverSettings,
                                                      credentials: pihole.credentials)
    }

    public func updateSystemInfo() async throws {
        pihole.systemInfo = try await service.fetchSystemInfo(serverSettings: pihole.serverSettings,
                                                              credentials: pihole.credentials)
    }

    public func updateSensorData() async throws {
        pihole.sensorData = try await service.fetchSensorData(serverSettings: pihole.serverSettings,
                                                              credentials: pihole.credentials)
    }

    public func setStatus(_ status: Pihole.Status) async throws {
        pihole.status = try await service.setStatus(status, timer: nil,
                                                    serverSettings: pihole.serverSettings,
                                                    credentials: pihole.credentials)
    }

    public func updateDNSQueries() async throws {
        pihole.DNSQueries = try await service.fetchDNSQueries(serverSettings: pihole.serverSettings,
                                                              credentials: pihole.credentials)
    }
}
