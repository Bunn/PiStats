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
        }
    }
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
