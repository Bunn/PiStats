//
//  PiholeService.swift
//  PiStatsCore
//
//  Created by Fernando Bunn on 28/01/2025.
//

import OSLog

// MARK: - PiholeService Protocol

public protocol PiholeService: Sendable {
    var pihole: Pihole { get }

    func fetchSummary() async throws -> PiholeSummary
    func fetchStatus() async throws -> PiholeStatus
    func fetchSystemMetrics() async throws -> PiMonitorMetrics
    func fetchHistory() async throws -> [HistoryItem]
    func fetchTopDomains(count: Int) async throws -> TopDomainsResult
    func fetchTopClients(count: Int) async throws -> TopClientsResult
    func fetchQueryTypes() async throws -> QueryTypesResult
    func fetchUpstreams() async throws -> UpstreamsResult
    func fetchQueries(count: Int) async throws -> [QueryLogEntry]
    func fetchHealth() async throws -> PiholeHealth
    func clearMessages() async throws
    func enable() async throws -> PiholeStatus
    func disable(timer: Int?) async throws -> PiholeStatus

    /// Triggers a gravity (blocklist) rebuild on the Pi-hole. Pi-hole v6 only;
    /// v5 throws `PiholeServiceError.notSupported`.
    func updateGravity() async throws

    /// Returns the configured adlists (block + allow). Pi-hole v6 only.
    func fetchAdlists() async throws -> [AdList]

    /// Enables or disables a single adlist. Pi-hole v6 only.
    func setAdlist(_ adlist: AdList, enabled: Bool) async throws

    /// Returns the domain rules in a single bucket (allow/deny × exact/regex).
    /// Pi-hole v6 only; v5 throws `PiholeServiceError.notSupported`.
    func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule]

    /// Adds domain rules. Rules spanning multiple buckets are grouped and sent
    /// per bucket. Pi-hole v6 only.
    func addDomains(_ domains: [DomainRule]) async throws

    /// Removes domain rules (one DELETE per rule). Pi-hole v6 only.
    func removeDomains(_ domains: [DomainRule]) async throws

    /// Enables or disables a single existing domain rule. Pi-hole v6 only.
    func setDomain(_ domain: DomainRule, enabled: Bool) async throws

    /// When gravity last ran (most recent adlist update). Pi-hole v6 only.
    func fetchGravityLastUpdated() async throws -> Date?
}

extension PiholeService {
    func disable() async throws -> PiholeStatus {
        try await disable(timer: nil)
    }

    /// Fetches all four domain buckets concurrently. Pi-hole v6 only.
    public func fetchAllDomains() async throws -> [DomainRule] {
        try await withThrowingTaskGroup(of: [DomainRule].self) { group in
            for type in DomainListType.allCases {
                for kind in DomainListKind.allCases {
                    group.addTask { try await self.fetchDomains(type: type, kind: kind) }
                }
            }
            var all: [DomainRule] = []
            for try await chunk in group { all.append(contentsOf: chunk) }
            return all
        }
    }
}

public enum PiholeServiceError: Error, LocalizedError {
    case missingToken
    case invalidAuthenticationResponse
    case badURL
    case cannotParseResponse
    case unknownStatus
    case networkError(Error)
    case encodingError(Error)
    case unknownError
    case piMonitorNotSet
    case piMonitorError(PiMonitorError)
    case apiSeatsExceeded
    case notSupported

    public var errorDescription: String? {
        switch self {
        case .missingToken:
            return "Authentication token or password is missing. Please enter your Pi-hole password in the settings."
        case .invalidAuthenticationResponse:
            return "Invalid authentication response from Pi-hole. Please check your password and try again."
        case .badURL:
            return "Invalid Pi-hole URL. Please check the host address and port."
        case .cannotParseResponse:
            return "Unable to parse Pi-hole response. The server may be using an incompatible API version."
        case .unknownStatus:
            return "Unable to determine Pi-hole status."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Request encoding error: \(error.localizedDescription)"
        case .unknownError:
            return "An unknown error occurred while communicating with Pi-hole."
        case .piMonitorNotSet:
            return "Pi Monitor is not configured for this Pi-hole."
        case .piMonitorError(let error):
            return "Pi Monitor error: \(error.localizedDescription)"
        case .apiSeatsExceeded:
            return "Maximum number of API sessions exceeded on Pi-hole. Please close some other Pi-hole clients or increase the session limit."
        case .notSupported:
            return "This action isn't supported on this Pi-hole version."
        }
    }
}

extension PiholeService {
    /// Pi-hole v5 compatibility path. Pi-hole v6 implements this requirement
    /// using FTL's authenticated system and sensor API endpoints.
    func fetchSystemMetrics() async throws -> PiMonitorMetrics {
        Log.network.info("🖥️ [Service] Fetching legacy system metrics for \(pihole.name)")
        
        guard let metric = pihole.piMonitor else { 
            Log.network.error("❌ [Service] PiMonitor not configured for \(pihole.name)")
            throw PiholeServiceError.piMonitorNotSet 
        }

        return try await withCheckedThrowingContinuation { continuation in
            PiMonitorService().fetchMetrics(host: metric.host, port: metric.port) { result in
                switch result {
                case .success(let metrics):
                    Log.network.info("✅ [Service] Legacy system metrics fetched for \(pihole.name)")
                    continuation.resume(returning: metrics)
                case .failure(let error):
                    Log.network.error("💥 [Service] Legacy system metrics failed for \(pihole.name): \(error)")
                    continuation.resume(throwing: PiholeServiceError.piMonitorError(error))
                }
            }
        }
    }
}
