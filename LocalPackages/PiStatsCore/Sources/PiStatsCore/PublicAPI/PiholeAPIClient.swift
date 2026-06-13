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

    public init(_ pihole: Pihole, urlSession: URLSession = .shared) {
        self.pihole = pihole

        switch pihole.version {
        case .v5:
            self.service = PiholeV5Service(pihole, urlSession: urlSession)
            Log.network.info("🔧 [Client] Initialized V5 service for \(pihole.name)")
        case .v6:
            self.service = PiholeV6Service(pihole, urlSession: urlSession)
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

    public func fetchTopDomains(count: Int = 10) async throws -> TopDomainsResult {
        try await service.fetchTopDomains(count: count)
    }

    public func fetchTopClients(count: Int = 10) async throws -> TopClientsResult {
        try await service.fetchTopClients(count: count)
    }

    public func fetchQueryTypes() async throws -> QueryTypesResult {
        try await service.fetchQueryTypes()
    }

    public func fetchUpstreams() async throws -> UpstreamsResult {
        try await service.fetchUpstreams()
    }

    public func fetchQueries(count: Int = 200) async throws -> [QueryLogEntry] {
        try await service.fetchQueries(count: count)
    }

    public func fetchHealth() async throws -> PiholeHealth {
        try await service.fetchHealth()
    }

    public func clearMessages() async throws {
        try await service.clearMessages()
    }

    public func enable() async throws -> PiholeStatus {
        try await service.enable()
    }

    public func disable(timer: Int? = nil) async throws -> PiholeStatus {
        try await service.disable(timer: timer)
    }

    public func updateGravity() async throws {
        try await service.updateGravity()
    }

    public func fetchAdlists() async throws -> [AdList] {
        try await service.fetchAdlists()
    }

    public func setAdlist(_ adlist: AdList, enabled: Bool) async throws {
        try await service.setAdlist(adlist, enabled: enabled)
    }

    public func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule] {
        try await service.fetchDomains(type: type, kind: kind)
    }

    public func addDomains(_ domains: [DomainRule]) async throws {
        try await service.addDomains(domains)
    }

    public func removeDomains(_ domains: [DomainRule]) async throws {
        try await service.removeDomains(domains)
    }

    public func setDomain(_ domain: DomainRule, enabled: Bool) async throws {
        try await service.setDomain(domain, enabled: enabled)
    }

    public func fetchGravityLastUpdated() async throws -> Date? {
        try await service.fetchGravityLastUpdated()
    }
}
