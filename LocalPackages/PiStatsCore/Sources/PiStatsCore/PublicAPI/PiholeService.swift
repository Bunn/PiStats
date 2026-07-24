//
//  PiholeService.swift
//  PiStatsCore
//
//  Created by Fernando Bunn on 28/01/2025.
//

import Foundation

// MARK: - PiholeService Protocol

public protocol PiholeService: Sendable {
    var pihole: Pihole { get }

    func fetchSummary() async throws -> PiholeSummary
    func fetchStatus() async throws -> PiholeStatus
    func fetchSystemMetrics() async throws -> PiholeSystemMetrics
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

    /// Triggers a gravity (blocklist) rebuild on the Pi-hole.
    func updateGravity() async throws

    /// Returns the configured adlists (block + allow).
    func fetchAdlists() async throws -> [AdList]

    /// Enables or disables a single adlist.
    func setAdlist(_ adlist: AdList, enabled: Bool) async throws

    /// Returns the domain rules in a single bucket (allow/deny × exact/regex).
    func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule]

    /// Adds domain rules. Rules spanning multiple buckets are grouped and sent
    /// per bucket.
    func addDomains(_ domains: [DomainRule]) async throws

    /// Removes domain rules (one DELETE per rule).
    func removeDomains(_ domains: [DomainRule]) async throws

    /// Enables or disables a single existing domain rule.
    func setDomain(_ domain: DomainRule, enabled: Bool) async throws

    /// When gravity last ran (most recent adlist update).
    func fetchGravityLastUpdated() async throws -> Date?
}

extension PiholeService {
    func disable() async throws -> PiholeStatus {
        try await disable(timer: nil)
    }

    /// Fetches all four domain buckets concurrently.
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
    case missingPassword
    case invalidAuthenticationResponse
    case badURL
    case cannotParseResponse
    case unknownStatus
    case networkError(Error)
    case encodingError(Error)
    case unknownError
    case apiSeatsExceeded

    public var errorDescription: String? {
        switch self {
        case .missingPassword:
            return "Authentication password is missing. Please enter your Pi-hole password in the settings."
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
        case .apiSeatsExceeded:
            return "Maximum number of API sessions exceeded on Pi-hole. Please close some other Pi-hole clients or increase the session limit."
        }
    }
}
