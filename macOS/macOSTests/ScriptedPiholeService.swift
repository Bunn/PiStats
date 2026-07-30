import Foundation
import PiStatsCore

enum ScriptedResponse<Value: Sendable>: Sendable {
    case value(Value, delay: Duration = .zero)
    case networkFailure(delay: Duration = .zero)
    case authenticationFailure(delay: Duration = .zero)

    func resolve() async throws -> Value {
        let delay = switch self {
        case .value(_, let delay), .networkFailure(let delay), .authenticationFailure(let delay):
            delay
        }
        try await Task.sleep(for: delay)

        switch self {
        case .value(let value, _):
            return value
        case .networkFailure:
            throw PiholeServiceError.networkError(URLError(.timedOut))
        case .authenticationFailure:
            throw PiholeServiceError.invalidAuthenticationResponse
        }
    }
}

actor ScriptedPiholeService: PiholeService {
    nonisolated let pihole: Pihole

    private var summaryResponses: [ScriptedResponse<PiholeSummary>]
    private var statusResponses: [ScriptedResponse<PiholeStatus>]
    private let mutationShouldFail: Bool
    private(set) var summaryRequestCount = 0
    private(set) var statusRequestCount = 0
    private(set) var supplementaryRequestCount = 0
    private(set) var addDomainsRequestCount = 0

    init(
        pihole: Pihole,
        summaries: [ScriptedResponse<PiholeSummary>],
        statuses: [ScriptedResponse<PiholeStatus>],
        mutationShouldFail: Bool = false
    ) {
        self.pihole = pihole
        self.summaryResponses = summaries
        self.statusResponses = statuses
        self.mutationShouldFail = mutationShouldFail
    }

    func fetchSummary() async throws -> PiholeSummary {
        summaryRequestCount += 1
        let response = nextResponse(
            from: &summaryResponses,
            fallback: .networkFailure()
        )
        return try await response.resolve()
    }

    func fetchStatus() async throws -> PiholeStatus {
        statusRequestCount += 1
        let response = nextResponse(
            from: &statusResponses,
            fallback: .networkFailure()
        )
        return try await response.resolve()
    }

    func fetchSystemMetrics() async throws -> PiholeSystemMetrics {
        supplementaryRequestCount += 1
        throw PiholeServiceError.cannotParseResponse
    }

    func fetchHistory() async throws -> [HistoryItem] {
        supplementaryRequestCount += 1
        return []
    }

    func fetchTopDomains(count: Int) async throws -> TopDomainsResult {
        supplementaryRequestCount += 1
        return TopDomainsResult(topPermitted: [], topBlocked: [])
    }

    func fetchTopClients(count: Int) async throws -> TopClientsResult {
        supplementaryRequestCount += 1
        return TopClientsResult(topActive: [], topBlocked: [])
    }

    func fetchQueryTypes() async throws -> QueryTypesResult {
        supplementaryRequestCount += 1
        return QueryTypesResult(types: [])
    }

    func fetchUpstreams() async throws -> UpstreamsResult {
        supplementaryRequestCount += 1
        return UpstreamsResult(upstreams: [])
    }

    func fetchQueries(count: Int) async throws -> [QueryLogEntry] {
        []
    }

    func fetchHealth() async throws -> PiholeHealth {
        supplementaryRequestCount += 1
        return PiholeHealth(
            coreVersion: nil,
            webVersion: nil,
            ftlVersion: nil,
            updateAvailable: false,
            messages: []
        )
    }

    func clearMessages() async throws {}

    func enable() async throws -> PiholeStatus {
        .enabled
    }

    func disable(timer: Int?) async throws -> PiholeStatus {
        .disabled
    }

    func updateGravity() async throws {}

    func fetchAdlists() async throws -> [AdList] {
        []
    }

    func setAdlist(_ adlist: AdList, enabled: Bool) async throws {}

    func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule] {
        []
    }

    func addDomains(_ domains: [DomainRule]) async throws {
        addDomainsRequestCount += 1
        if mutationShouldFail {
            throw PiholeServiceError.networkError(URLError(.cannotConnectToHost))
        }
    }

    func removeDomains(_ domains: [DomainRule]) async throws {}

    func setDomain(_ domain: DomainRule, enabled: Bool) async throws {}

    func fetchGravityLastUpdated() async throws -> Date? {
        nil
    }

    private func nextResponse<Value: Sendable>(
        from responses: inout [ScriptedResponse<Value>],
        fallback: ScriptedResponse<Value>
    ) -> ScriptedResponse<Value> {
        responses.isEmpty ? fallback : responses.removeFirst()
    }
}
