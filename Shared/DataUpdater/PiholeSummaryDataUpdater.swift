//
//  PiholeSummaryDataUpdater.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import Foundation
import PiStatsCore
import SwiftUI

// MARK: - Error Handling Protocol

@MainActor
protocol ErrorHandling {
    func handleError(_ error: Error, context: ErrorContext)
}

enum ErrorContext {
    case fetchingSummary
    case fetchingStatus
    case fetchingSystemMetrics
    case enablingPihole
    case disablingPihole

    var affectsPiholeStatus: Bool {
        self != .fetchingSystemMetrics
    }
}

// MARK: - Error Mapper

struct PiholeErrorMapper {
    static func mapError(_ error: Error, context: ErrorContext) -> PiholeError {
        let errorType = determineErrorType(error, context: context)
        return PiholeError(
            type: errorType,
            originalError: error,
            timestamp: .now
        )
    }
    
    private static func determineErrorType(_ error: Error, context: ErrorContext) -> PiholeError.ErrorType {
        if let serviceError = error as? PiholeServiceError {
            switch serviceError {
            case .missingPassword, .invalidAuthenticationResponse, .apiSeatsExceeded:
                return .authenticationError
            case .badURL:
                return .invalidConfiguration
            case .cannotParseResponse:
                return .parsingError
            case .unknownStatus:
                return .serverError
            case .networkError:
                return .networkError
            case .encodingError:
                return .parsingError
            case .unknownError:
                return .unknown
            }
        }
        
        // Check for common network errors
        if let nsError = error as NSError? {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorTimedOut:
                return .networkError
            case NSURLErrorUserAuthenticationRequired:
                return .authenticationError
            default:
                break
            }
        }
        
        return .unknown
    }
}

@MainActor
final class PiholeSummaryDataUpdater: Identifiable, ObservableObject, ErrorHandling {
    let id = UUID()
    let pihole: Pihole
    private let service: PiholeService
    @Published private(set) var summary: PiholeSummaryData

    private let primaryPollInterval: Duration
    private let primaryRetryInterval: Duration
    private let supplementaryRefreshInterval: TimeInterval
    private let transientFailureThreshold: Int

    private var pollingTask: Task<Void, Never>?
    private var primaryRefreshTask: Task<Bool, Never>?
    private var supplementaryTask: Task<Void, Never>?
    private var lastSupplementaryRefresh: Date?
    private var consecutivePrimaryFailures = 0
    private var refreshGeneration = 0

    init(
        pihole: Pihole,
        service: PiholeService? = nil,
        initialSummary: PiholeSummaryData? = nil,
        primaryPollInterval: Duration = .seconds(5),
        primaryRetryInterval: Duration = .seconds(1),
        supplementaryRefreshInterval: TimeInterval = 30,
        transientFailureThreshold: Int = 2
    ) {
        self.pihole = pihole
        self.service = service ?? PiholeAPIClient(pihole)
        self.summary = initialSummary ?? PiholeSummaryData()
        self.primaryPollInterval = primaryPollInterval
        self.primaryRetryInterval = primaryRetryInterval
        self.supplementaryRefreshInterval = supplementaryRefreshInterval
        self.transientFailureThreshold = max(1, transientFailureThreshold)
        setupInitialData()
    }

    private func setupInitialData() {
        summary.name = pihole.name
    }

    func startUpdating() {
        guard pollingTask == nil else { return }

        if !summary.hasPrimaryData {
            summary.connectionState = .connecting
        }

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                let succeeded = await self?.refreshNow() ?? true
                let interval = self?.pollInterval(afterSuccessfulRefresh: succeeded) ?? .seconds(5)

                do {
                    try await Task.sleep(for: interval)
                } catch {
                    return
                }
            }
        }
    }

    @discardableResult
    func refreshNow(includeSupplementaryData: Bool = true) async -> Bool {
        let generation = refreshGeneration

        if let primaryRefreshTask {
            let succeeded = await primaryRefreshTask.value
            guard generation == refreshGeneration else { return false }

            if includeSupplementaryData {
                scheduleSupplementaryRefreshIfNeeded(primarySucceeded: succeeded)
            }
            return succeeded
        }

        let task = Task { [weak self] in
            await self?.performPrimaryRefresh() ?? false
        }
        primaryRefreshTask = task

        let succeeded = await task.value
        guard generation == refreshGeneration else { return false }

        primaryRefreshTask = nil

        if includeSupplementaryData {
            scheduleSupplementaryRefreshIfNeeded(primarySucceeded: succeeded)
        }
        return succeeded
    }

    private func pollInterval(afterSuccessfulRefresh succeeded: Bool) -> Duration {
        succeeded ? primaryPollInterval : primaryRetryInterval
    }

    /// Fetches the query log on demand (not part of the periodic refresh).
    func fetchQueries(count: Int = 200) async throws -> [QueryLogEntry] {
        try await service.fetchQueries(count: count)
    }

    /// Triggers a gravity (blocklist) rebuild on demand. Pi-hole v6 only.
    func updateGravity() async throws {
        try await service.updateGravity()
    }

    /// Fetches the configured adlists on demand. Pi-hole v6 only.
    func fetchAdlists() async throws -> [AdList] {
        try await service.fetchAdlists()
    }

    /// Enables/disables a single adlist. Pi-hole v6 only.
    func setAdlist(_ adlist: AdList, enabled: Bool) async throws {
        try await service.setAdlist(adlist, enabled: enabled)
    }

    /// Fetches a single domain bucket (allow/deny × exact/regex) on demand. Pi-hole v6 only.
    func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule] {
        try await service.fetchDomains(type: type, kind: kind)
    }

    /// Fetches all four domain buckets on demand. Pi-hole v6 only.
    func fetchAllDomains() async throws -> [DomainRule] {
        try await service.fetchAllDomains()
    }

    /// Adds domain rules. Pi-hole v6 only.
    func addDomains(_ domains: [DomainRule]) async throws {
        try await service.addDomains(domains)
    }

    /// Removes domain rules. Pi-hole v6 only.
    func removeDomains(_ domains: [DomainRule]) async throws {
        try await service.removeDomains(domains)
    }

    /// Enables/disables a single domain rule. Pi-hole v6 only.
    func setDomain(_ domain: DomainRule, enabled: Bool) async throws {
        try await service.setDomain(domain, enabled: enabled)
    }

    /// When gravity last ran. Pi-hole v6 only.
    func fetchGravityLastUpdated() async throws -> Date? {
        try await service.fetchGravityLastUpdated()
    }

    /// Clears the Pi-hole's FTL diagnosis messages, then refreshes health.
    func clearMessages() async {
        do {
            try await service.clearMessages()
            let health = try await service.fetchHealth()
            updateHealth(with: health)
        } catch {
            Log.network.error("❌ Failed to clear messages for \(self.pihole.name, privacy: .public): \(String(describing: error), privacy: .public)")
        }
    }

    func enable() async {
        do {
            let result = try await service.enable()
            updateStatus(with: result)
            recordPrimarySuccess()
        } catch {
            handleError(error, context: .enablingPihole)
        }
    }

    func disable() async {
        do {
            let result = try await service.disable(timer: nil)
            updateStatus(with: result)
            recordPrimarySuccess()
        } catch {
            handleError(error, context: .disablingPihole)
        }
    }

    func disable(timer: Int?) async {
        do {
            let result = try await service.disable(timer: timer)
            updateStatus(with: result)
            recordPrimarySuccess()
        } catch {
            handleError(error, context: .disablingPihole)
        }
    }

    func stopUpdating() {
        refreshGeneration &+= 1
        pollingTask?.cancel()
        pollingTask = nil
        primaryRefreshTask?.cancel()
        primaryRefreshTask = nil
        supplementaryTask?.cancel()
        supplementaryTask = nil
        summary.isRefreshing = false
    }

}

private extension PiholeSummaryDataUpdater {
    enum PrimaryRefreshOutcome: Sendable {
        case success
        case failure(PiholeError)
        case cancelled

        var error: PiholeError? {
            if case .failure(let error) = self {
                error
            } else {
                nil
            }
        }

        var succeeded: Bool {
            if case .success = self {
                true
            } else {
                false
            }
        }
    }

    func performPrimaryRefresh() async -> Bool {
        summary.isRefreshing = true
        if !summary.hasPrimaryData {
            summary.connectionState = .connecting
        }
        defer { summary.isRefreshing = false }

        async let summaryOutcome = refreshSummary()
        async let statusOutcome = refreshStatus()
        let outcomes = await (summaryOutcome, statusOutcome)

        guard !Task.isCancelled else { return false }

        let results = [outcomes.0, outcomes.1]
        if results.contains(where: \.succeeded) {
            recordPrimarySuccess()
            return true
        }

        let errors = results.compactMap(\.error)
        guard let preferredError = errors.first(where: { !$0.type.isTransient }) ?? errors.first else {
            return false
        }

        consecutivePrimaryFailures += 1
        let shouldSurfaceError = !preferredError.type.isTransient
            || consecutivePrimaryFailures >= transientFailureThreshold

        summary.connectionState = shouldSurfaceError
            ? .unavailable
            : (summary.hasPrimaryData ? .stale : .connecting)

        if shouldSurfaceError {
            setError(preferredError, context: .fetchingSummary)
        }
        return false
    }

    func refreshSummary() async -> PrimaryRefreshOutcome {
        do {
            let result = try await service.fetchSummary()
            try Task.checkCancellation()
            updateSummary(with: result)
            summary.hasLoadedSummary = true
            return .success
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failure(PiholeErrorMapper.mapError(error, context: .fetchingSummary))
        }
    }

    func refreshStatus() async -> PrimaryRefreshOutcome {
        do {
            let status = try await service.fetchStatus()
            try Task.checkCancellation()
            updateStatus(with: status)
            summary.hasLoadedStatus = true
            return .success
        } catch is CancellationError {
            return .cancelled
        } catch {
            return .failure(PiholeErrorMapper.mapError(error, context: .fetchingStatus))
        }
    }

    func recordPrimarySuccess() {
        consecutivePrimaryFailures = 0
        summary.connectionState = .connected
        summary.lastSuccessfulRefresh = .now
        clearError()
    }

    func scheduleSupplementaryRefreshIfNeeded(primarySucceeded: Bool) {
        guard primarySucceeded, supplementaryTask == nil else { return }

        if let lastSupplementaryRefresh,
           Date.now.timeIntervalSince(lastSupplementaryRefresh) < supplementaryRefreshInterval {
            return
        }

        lastSupplementaryRefresh = .now
        let generation = refreshGeneration
        supplementaryTask = Task { [weak self] in
            await self?.performSupplementaryRefresh()

            guard let self, self.refreshGeneration == generation else { return }
            self.supplementaryTask = nil
        }
    }

    func performSupplementaryRefresh() async {
        async let firstPipeline: Void = refreshSupplementaryFirstPipeline()
        async let secondPipeline: Void = refreshSupplementarySecondPipeline()
        _ = await (firstPipeline, secondPipeline)
    }

    func refreshSupplementaryFirstPipeline() async {
        await refreshTopDomains()
        await refreshQueryTypes()
        await refreshHealth()
    }

    func refreshSupplementarySecondPipeline() async {
        await refreshTopClients()
        await refreshHistory()
        await refreshUpstreams()
        if service.pihole.systemMetricsEnabled {
            await refreshSystemMetrics()
        }
    }

    func refreshTopDomains() async {
        await loadSupplementaryData("top domains") {
            try await self.service.fetchTopDomains(count: 10)
        } update: {
            self.updateTopDomains(with: $0)
        }
    }

    func refreshTopClients() async {
        await loadSupplementaryData("top clients") {
            try await self.service.fetchTopClients(count: 10)
        } update: {
            self.updateTopClients(with: $0)
        }
    }

    func refreshHistory() async {
        await loadSupplementaryData("history") {
            try await self.service.fetchHistory()
        } update: {
            self.updateHistory(with: $0)
        }
    }

    func refreshQueryTypes() async {
        await loadSupplementaryData("query types") {
            try await self.service.fetchQueryTypes()
        } update: {
            self.updateQueryTypes(with: $0)
        }
    }

    func refreshUpstreams() async {
        await loadSupplementaryData("upstreams") {
            try await self.service.fetchUpstreams()
        } update: {
            self.updateUpstreams(with: $0)
        }
    }

    func refreshHealth() async {
        await loadSupplementaryData("health") {
            try await self.service.fetchHealth()
        } update: {
            self.updateHealth(with: $0)
        }
    }

    func refreshSystemMetrics() async {
        await loadSupplementaryData("system metrics") {
            try await self.service.fetchSystemMetrics()
        } update: {
            self.updateSystemMetrics(with: $0)
        }
    }

    func loadSupplementaryData<Value: Sendable>(
        _ label: String,
        operation: () async throws -> Value,
        update: (Value) -> Void
    ) async {
        guard !Task.isCancelled else { return }

        do {
            let value = try await operation()
            try Task.checkCancellation()
            update(value)
        } catch is CancellationError {
            return
        } catch {
            Log.network.error(
                "❌ Supplementary \(label, privacy: .public) fetch failed for \(self.pihole.name, privacy: .public): \(String(describing: error), privacy: .public)"
            )
        }
    }
}

// MARK: - Error Handling Implementation

extension PiholeSummaryDataUpdater {
    func handleError(_ error: Error, context: ErrorContext) {
        guard context.affectsPiholeStatus else {
            Log.network.error(
                "❌ Supplementary system metrics fetch failed for \(self.pihole.name, privacy: .public): \(String(describing: error), privacy: .public)"
            )
            return
        }

        let piholeError = PiholeErrorMapper.mapError(error, context: context)
        summary.connectionState = summary.hasPrimaryData ? .stale : .unavailable
        setError(piholeError, context: context)
    }
    
    private func setError(_ error: PiholeError, context: ErrorContext) {
        withAnimation {
            summary.currentError = error
            if !summary.hasError { summary.hasError = true }
            if context.affectsPiholeStatus, !summary.hasPiholeError {
                summary.hasPiholeError = true
            }
        }
    }

    private func clearError() {
        guard summary.hasError || summary.currentError != nil || summary.hasPiholeError else { return }
        withAnimation {
            summary.currentError = nil
            summary.hasError = false
            summary.hasPiholeError = false
        }
    }
}

// MARK: - Summary and Status Updates
extension PiholeSummaryDataUpdater {

    private func updateSummary(with result: PiholeSummary) {
        let blocked = result.adsBlocked.formatted()
        let domains = result.domainsBeingBlocked.formatted()
        let percentage = result.adsPercentageToday.formattedPercentage()
        let queries = result.queries.formatted()
        withAnimation {
            if summary.queriesBlocked != blocked { summary.queriesBlocked = blocked }
            if summary.domainsOnList != domains { summary.domainsOnList = domains }
            if summary.percentageBlocked != percentage { summary.percentageBlocked = percentage }
            if summary.totalQueries != queries { summary.totalQueries = queries }
            summary.hasLoadedSummary = true
        }
    }

    private func updateTopDomains(with result: TopDomainsResult) {
        withAnimation { summary.topDomains = result }
    }

    private func updateTopClients(with result: TopClientsResult) {
        withAnimation { summary.topClients = result }
    }

    private func updateHistory(with result: [HistoryItem]) {
        withAnimation { summary.history = result }
    }

    private func updateQueryTypes(with result: QueryTypesResult) {
        withAnimation { summary.queryTypes = result }
    }

    private func updateUpstreams(with result: UpstreamsResult) {
        withAnimation { summary.upstreams = result }
    }

    private func updateHealth(with result: PiholeHealth) {
        withAnimation { summary.health = result }
    }

    private func updateSystemMetrics(with metrics: PiholeSystemMetrics) {
        withAnimation { summary.systemMetrics = metrics }
    }

    private func updateStatus(with status: PiholeStatus) {
        withAnimation {
            if summary.status != status { summary.status = status }
            summary.hasLoadedStatus = true
        }
    }
}

// MARK: - Formatting Extensions

private let decimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

private let percentFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.maximumFractionDigits = 2
    return formatter
}()

extension Int {
    func formatted() -> String {
        decimalFormatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

extension Double {
    func formattedPercentage() -> String {
        percentFormatter.string(from: NSNumber(value: self / 100)) ?? "0%"
    }
}

// MARK: - Array Sorting Extension
extension Array where Element == PiholeSummaryDataUpdater {
    func sortedByNameThenHost() -> [PiholeSummaryDataUpdater] {
        return sorted { lhs, rhs in
            if lhs.pihole.name.lowercased() != rhs.pihole.name.lowercased() {
                return lhs.pihole.name.lowercased() < rhs.pihole.name.lowercased()
            }
            return lhs.pihole.address.lowercased() < rhs.pihole.address.lowercased()
        }
    }
}
