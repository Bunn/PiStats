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

protocol ErrorHandling {
    func handleError(_ error: Error, context: ErrorContext)
}

enum ErrorContext {
    case fetchingSummary
    case fetchingStatus
    case fetchingMonitorMetrics
    case enablingPihole
    case disablingPihole
}

// MARK: - Error Mapper

struct PiholeErrorMapper {
    static func mapError(_ error: Error, context: ErrorContext) -> PiholeError {
        let errorType = determineErrorType(error, context: context)
        return PiholeError(
            type: errorType,
            originalError: error,
            timestamp: Date()
        )
    }
    
    private static func determineErrorType(_ error: Error, context: ErrorContext) -> PiholeError.ErrorType {
        if let serviceError = error as? PiholeServiceError {
            switch serviceError {
            case .missingToken, .invalidAuthenticationResponse, .apiSeatsExceeded:
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
            case .piMonitorNotSet:
                return .invalidConfiguration
            case .piMonitorError:
                return .monitorError
            case .unknownError:
                return .unknown
            }
        }
        
        if error is PiMonitorError {
            return .monitorError
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

final class PiholeSummaryDataUpdater: Identifiable, ObservableObject, ErrorHandling {
    let id = UUID()
    let pihole: Pihole
    private let service: PiholeService
    @Published private(set) var summary: PiholeSummaryData
    private var timer: Timer?
    private var fetchTasks: [Task<Void, Never>] = []

    init(pihole: Pihole) {
        self.pihole = pihole
        self.service = PiholeAPIClient(pihole)
        self.summary = PiholeSummaryData()
        setupInitialData()
    }

    private func setupInitialData() {
        summary.name = pihole.name
        summary.queriesBlocked = "0"
        summary.domainsOnList = "0"
        summary.percentageBlocked = "0"
        summary.totalQueries = "0"
    }

    func startUpdating() {
        stopUpdating()
        updateData()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateData()
        }
    }

    func enable() async {
        do {
            let result = try await service.enable()
            await updateStatus(with: result)
            await clearError()
        } catch {
            handleError(error, context: .enablingPihole)
        }
    }

    func disable() async {
        do {
            let result = try await service.disable(timer: nil)
            await updateStatus(with: result)
            await clearError()
        } catch {
            handleError(error, context: .disablingPihole)
        }
    }

    func disable(timer: Int?) async {
        do {
            let result = try await service.disable(timer: timer)
            await updateStatus(with: result)
            await clearError()
        } catch {
            handleError(error, context: .disablingPihole)
        }
    }

    private func updateData() {
        cancelFetchTasks()

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await service.fetchSummary()
                try Task.checkCancellation()
                await updateSummary(with: result)
                await clearError()
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                handleError(error, context: .fetchingSummary)
            }
        })

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                let status = try await service.fetchStatus()
                try Task.checkCancellation()
                await updateStatus(with: status)
                await clearError()
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                await updateStatus(with: .unknown)
                handleError(error, context: .fetchingStatus)
            }
        })

        let piholeNameForLog = pihole.name
        let piholeVersionForLog = pihole.version.rawValue
        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            Log.network.info("📊 Fetching top domains for \(piholeNameForLog, privacy: .public) (version: \(piholeVersionForLog, privacy: .public))")
            do {
                let result = try await service.fetchTopDomains(count: 10)
                try Task.checkCancellation()
                Log.network.info("✅ Top domains fetched for \(piholeNameForLog, privacy: .public) - \(result.topPermitted.count, privacy: .public) permitted, \(result.topBlocked.count, privacy: .public) blocked")
                await updateTopDomains(with: result)
            } catch is CancellationError {
                Log.network.info("⏹️ Top domains fetch cancelled for \(piholeNameForLog, privacy: .public)")
            } catch {
                Log.network.error("❌ Top domains fetch failed for \(piholeNameForLog, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        })

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            Log.network.info("👥 Fetching top clients for \(piholeNameForLog, privacy: .public) (version: \(piholeVersionForLog, privacy: .public))")
            do {
                let result = try await service.fetchTopClients(count: 10)
                try Task.checkCancellation()
                Log.network.info("✅ Top clients fetched for \(piholeNameForLog, privacy: .public) - \(result.topActive.count, privacy: .public) active, \(result.topBlocked.count, privacy: .public) blocked")
                await updateTopClients(with: result)
            } catch is CancellationError {
                Log.network.info("⏹️ Top clients fetch cancelled for \(piholeNameForLog, privacy: .public)")
            } catch {
                Log.network.error("❌ Top clients fetch failed for \(piholeNameForLog, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        })

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            Log.network.info("📈 Fetching history for \(piholeNameForLog, privacy: .public) (version: \(piholeVersionForLog, privacy: .public))")
            do {
                let result = try await service.fetchHistory()
                try Task.checkCancellation()
                Log.network.info("✅ History fetched for \(piholeNameForLog, privacy: .public) - \(result.count, privacy: .public) buckets")
                await updateHistory(with: result)
            } catch is CancellationError {
                Log.network.info("⏹️ History fetch cancelled for \(piholeNameForLog, privacy: .public)")
            } catch {
                Log.network.error("❌ History fetch failed for \(piholeNameForLog, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        })

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await service.fetchQueryTypes()
                try Task.checkCancellation()
                await updateQueryTypes(with: result)
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                Log.network.error("❌ Query types fetch failed for \(piholeNameForLog, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        })

        fetchTasks.append(Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await service.fetchUpstreams()
                try Task.checkCancellation()
                await updateUpstreams(with: result)
            } catch is CancellationError {
                // Task was cancelled, do nothing
            } catch {
                Log.network.error("❌ Upstreams fetch failed for \(piholeNameForLog, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        })

        if service.pihole.piMonitor != nil {
            fetchTasks.append(Task { [weak self] in
                guard let self else { return }
                do {
                    let result = try await service.fetchMonitorMetrics()
                    try Task.checkCancellation()
                    await updateMonitorMetrics(with: result)
                } catch is CancellationError {
                    // Task was cancelled, do nothing
                } catch {
                    handleError(error, context: .fetchingMonitorMetrics)
                }
            })
        }
    }

    private func cancelFetchTasks() {
        fetchTasks.forEach { $0.cancel() }
        fetchTasks.removeAll()
    }

    func stopUpdating() {
        timer?.invalidate()
        timer = nil
        cancelFetchTasks()
    }

    /// Stops the timer without cancelling in-flight tasks.
    /// Use when replacing this updater with a new one to avoid
    /// TCP connection resets on URLSession.shared that can interfere
    /// with the new updater's requests to the same host.
    func prepareForReplacement() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Error Handling Implementation

extension PiholeSummaryDataUpdater {
    func handleError(_ error: Error, context: ErrorContext) {
        let piholeError = PiholeErrorMapper.mapError(error, context: context)
        Task {
            await setError(piholeError)
        }
    }
    
    @MainActor
    private func setError(_ error: PiholeError) {
        withAnimation {
            summary.currentError = error
            summary.hasError = true
        }
    }
    
    @MainActor
    private func clearError() {
        withAnimation {
            summary.currentError = nil
            summary.hasError = false
        }
    }
}

// MARK: - Summary and Status Updates
extension PiholeSummaryDataUpdater {

    @MainActor
    private func updateSummary(with result: PiholeSummary) {
        withAnimation {
            summary.queriesBlocked = result.adsBlocked.formatted()
            summary.domainsOnList = result.domainsBeingBlocked.formatted()
            summary.percentageBlocked = result.adsPercentageToday.formattedPercentage()
            summary.totalQueries = result.queries.formatted()
        }
    }

    @MainActor
    private func updateTopDomains(with result: TopDomainsResult) {
        withAnimation {
            summary.topDomains = result
        }
    }

    @MainActor
    private func updateTopClients(with result: TopClientsResult) {
        withAnimation {
            summary.topClients = result
        }
    }

    @MainActor
    private func updateHistory(with result: [HistoryItem]) {
        withAnimation {
            summary.history = result
        }
    }

    @MainActor
    private func updateQueryTypes(with result: QueryTypesResult) {
        withAnimation {
            summary.queryTypes = result
        }
    }

    @MainActor
    private func updateUpstreams(with result: UpstreamsResult) {
        withAnimation {
            summary.upstreams = result
        }
    }

    @MainActor
    private func updateMonitorMetrics(with metrics: PiMonitorMetrics) {
        withAnimation {
            summary.monitorMetrics = metrics
        }
    }

    @MainActor
    private func updateStatus(with status: PiholeStatus) {
        withAnimation {
            summary.status = status
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
