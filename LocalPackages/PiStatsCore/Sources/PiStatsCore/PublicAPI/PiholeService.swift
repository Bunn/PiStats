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
    func fetchMonitorMetrics() async throws -> PiMonitorMetrics
    func fetchHistory() async throws -> [HistoryItem]
    func enable() async throws -> PiholeStatus
    func disable(timer: Int?) async throws -> PiholeStatus
}

extension PiholeService {
    func disable() async throws -> PiholeStatus {
        try await disable(timer: nil)
    }
}

public enum PiholeServiceError: Error {
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
}

extension PiholeService {
    func fetchMonitorMetrics() async throws -> PiMonitorMetrics {
        Log.network.info("🖥️ [Service] Fetching monitor metrics for \(pihole.name)")
        
        guard let metric = pihole.piMonitor else { 
            Log.network.error("❌ [Service] PiMonitor not configured for \(pihole.name)")
            throw PiholeServiceError.piMonitorNotSet 
        }

        return try await withCheckedThrowingContinuation { continuation in
            PiMonitorService().fetchMetrics(host: metric.host, port: metric.port) { result in
                switch result {
                case .success(let metrics):
                    Log.network.info("✅ [Service] Monitor metrics fetched for \(pihole.name)")
                    continuation.resume(returning: metrics)
                case .failure(let error):
                    Log.network.error("💥 [Service] Monitor metrics failed for \(pihole.name): \(error)")
                    continuation.resume(throwing: PiholeServiceError.piMonitorError(error))
                }
            }
        }
    }
}
