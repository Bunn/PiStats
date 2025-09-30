//
//  PiholeAPIClient.swift
//  PiStatsCore
//
//  Created by Fernando Bunn on 28/01/2025.
//

import OSLog

// MARK: - PiholeAPIClient

public struct PiholeAPIClient: PiholeService {
    private let service: PiholeService
    public let pihole: Pihole

    public init(_ pihole: Pihole) {
        self.pihole = pihole

        switch pihole.version {
        case .v5:
            self.service = PiholeV5Service(pihole)
            Log.network.info("🔧 [Client] Initialized V5 service for \(pihole.name)")
        case .v6:
            self.service = PiholeV6Service(pihole)
            Log.network.info("🔧 [Client] Initialized V6 service for \(pihole.name)")
        }
    }

    public func fetchSummary() async throws -> PiholeSummary {
        try await service.fetchSummary()
    }

    public func fetchMonitorMetrics() async throws -> PiMonitorMetrics {
        try await service.fetchMonitorMetrics()
    }

    public func fetchStatus() async throws -> PiholeStatus {
        try await service.fetchStatus()
    }

    public func fetchHistory() async throws -> [HistoryItem] {
        try await service.fetchHistory()
    }

    public func enable() async throws -> PiholeStatus {
        try await service.enable()
    }

    public func disable(timer: Int? = nil) async throws -> PiholeStatus {
        try await service.disable(timer: timer)
    }
}
