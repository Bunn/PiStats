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
        fetchSummaryData()
        fetchStatusData()
        fetchMonitorData()
    }

    private func fetchMonitorData() {
        guard service.pihole.piMonitor != nil else { return }
        Task {
            do {
                let result = try await self.service.fetchMonitorMetrics()
                await self.updateMonitorMetrics(with: result)
            } catch {
                self.handleError(error, context: .fetchingMonitorMetrics)
            }
        }
    }

    private func fetchSummaryData() {
        Task {
            do {
                let result = try await service.fetchSummary()
                await updateSummary(with: result)
                await clearError()
            } catch {
                handleError(error, context: .fetchingSummary)
            }
        }
    }

    private func fetchStatusData() {
        Task {
            do {
                let status = try await service.fetchStatus()
                await updateStatus(with: status)
                await clearError()
            } catch {
                await updateStatus(with: .unknown)
                handleError(error, context: .fetchingStatus)
            }
        }
    }

    func stopUpdating() {
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
    private func updateMonitorMetrics(with metrics: PiMonitorMetrics) {
        withAnimation {
            summary.monitorMetrics = metrics
        }
        // Force objectWillChange to fire to ensure UI updates
        summary.objectWillChange.send()
        objectWillChange.send()
    }

    @MainActor
    private func updateStatus(with status: PiholeStatus) {
        objectWillChange.send()

        withAnimation {
            summary.status = status
        }

        objectWillChange.send()
    }
}

// MARK: - Formatting Extensions
extension Int {
    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "0"
    }
}

extension Double {
    func formattedPercentage() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self / 100)) ?? "0%"
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
