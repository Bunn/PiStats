//
//  MockPiMonitorService.swift
//  PiStatsCoreTests
//
//  Created for testing purposes
//

import Foundation
@testable import PiStatsCore

/// Mock implementation of PiMonitorServiceProtocol for testing
class MockPiMonitorService: PiMonitorServiceProtocol {
    var timeoutInterval: TimeInterval = 30
    var urlSession: URLSession = .shared
    
    // Test controls
    var shouldSucceed: Bool = true
    var mockMetrics: PiMonitorMetrics?
    var mockError: PiMonitorError?
    var fetchMetricsCallCount: Int = 0
    var lastHost: String?
    var lastPort: Int?
    var lastSecure: Bool?
    
    func fetchMetrics(host: String, port: Int?, secure: Bool, completion: @escaping (Result<PiMonitorMetrics, PiMonitorError>) -> ()) {
        fetchMetricsCallCount += 1
        lastHost = host
        lastPort = port
        lastSecure = secure
        
        if shouldSucceed {
            if let metrics = mockMetrics {
                completion(.success(metrics))
            } else {
                // Default mock metrics
                let defaultMetrics = PiMonitorMetrics(
                    socTemperature: 45.5,
                    uptime: 86400.0,
                    loadAverage: [0.5, 0.6, 0.7],
                    kernelRelease: "5.10.0-rpi1",
                    memory: PiMonitorMetrics.Memory(
                        totalMemory: 4096000,
                        freeMemory: 2048000,
                        availableMemory: 3072000
                    )
                )
                completion(.success(defaultMetrics))
            }
        } else {
            if let error = mockError {
                completion(.failure(error))
            } else {
                completion(.failure(.invalidResponse))
            }
        }
    }
    
    /// Reset mock state
    func reset() {
        shouldSucceed = true
        mockMetrics = nil
        mockError = nil
        fetchMetricsCallCount = 0
        lastHost = nil
        lastPort = nil
        lastSecure = nil
    }
}

