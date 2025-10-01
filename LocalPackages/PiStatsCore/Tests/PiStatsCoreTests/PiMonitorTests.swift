//
//  PiMonitorTests.swift
//  PiStatsCoreTests
//
//  Created for testing PiMonitor with mocks
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("PiMonitor Tests", .serialized)
struct PiMonitorTests {
    
    // MARK: - Tests with Mock Service
    
    @Test("fetchMetrics succeeds with mock service")
    func testFetchMetricsWithMockSuccess() async throws {
        let mockService = MockPiMonitorService()
        mockService.shouldSucceed = true
        mockService.mockMetrics = PiMonitorMetrics(
            socTemperature: 55.0,
            uptime: 100000.0,
            loadAverage: [1.0, 1.5, 2.0],
            kernelRelease: "6.0.0",
            memory: PiMonitorMetrics.Memory(
                totalMemory: 8192000,
                freeMemory: 4096000,
                availableMemory: 6144000
            )
        )
        
        let environment = PiMonitorEnvironment(host: "test.local", port: 8088, secure: false)
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        let metrics = try await monitor.fetchMetrics()
        
        #expect(metrics.socTemperature == 55.0)
        #expect(metrics.uptime == 100000.0)
        #expect(metrics.loadAverage == [1.0, 1.5, 2.0])
        #expect(metrics.kernelRelease == "6.0.0")
        #expect(mockService.fetchMetricsCallCount == 1)
        #expect(mockService.lastHost == "test.local")
        #expect(mockService.lastPort == 8088)
        #expect(mockService.lastSecure == false)
    }
    
    @Test("fetchMetrics fails with mock service error")
    func testFetchMetricsWithMockFailure() async throws {
        let mockService = MockPiMonitorService()
        mockService.shouldSucceed = false
        mockService.mockError = .malformedURL
        
        let environment = PiMonitorEnvironment(host: "invalid", port: 8088)
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        do {
            let _ = try await monitor.fetchMetrics()
            Issue.record("Should have thrown error")
        } catch let error as PiMonitorError {
            if case .malformedURL = error {
                // Expected error
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        }
        
        #expect(mockService.fetchMetricsCallCount == 1)
    }
    
    @Test("fetchMetrics with callback uses mock service")
    func testFetchMetricsCallbackWithMock() async throws {
        let mockService = MockPiMonitorService()
        mockService.shouldSucceed = true
        
        let environment = PiMonitorEnvironment(host: "callback.test", port: 9000, secure: true)
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        await withCheckedContinuation { continuation in
            monitor.fetchMetrics { result in
                switch result {
                case .success(let metrics):
                    #expect(metrics.socTemperature == 45.5)
                    #expect(mockService.lastHost == "callback.test")
                    #expect(mockService.lastPort == 9000)
                    #expect(mockService.lastSecure == true)
                case .failure(let error):
                    Issue.record("Should not fail: \(error)")
                }
                continuation.resume()
            }
        }
        
        #expect(mockService.fetchMetricsCallCount == 1)
    }
    
    @Test("timeout interval is configurable")
    func testTimeoutInterval() {
        let mockService = MockPiMonitorService()
        let environment = PiMonitorEnvironment(host: "test.local")
        var monitor = PiMonitor(service: mockService, environment: environment)
        
        #expect(mockService.timeoutInterval == 30) // Default
        
        monitor.timeoutInterval = 60
        #expect(mockService.timeoutInterval == 60)
    }
    
    @Test("PiMonitor uses default metrics when mock doesn't provide them")
    func testDefaultMockMetrics() async throws {
        let mockService = MockPiMonitorService()
        mockService.shouldSucceed = true
        mockService.mockMetrics = nil // Use default
        
        let environment = PiMonitorEnvironment(host: "default.test")
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        let metrics = try await monitor.fetchMetrics()
        
        // Should get default mock metrics
        #expect(metrics.socTemperature == 45.5)
        #expect(metrics.uptime == 86400.0)
        #expect(metrics.loadAverage.count == 3)
    }
    
    @Test("Mock service tracks multiple calls")
    func testMultipleCalls() async throws {
        let mockService = MockPiMonitorService()
        let environment = PiMonitorEnvironment(host: "multi.test")
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        #expect(mockService.fetchMetricsCallCount == 0)
        
        let _ = try await monitor.fetchMetrics()
        #expect(mockService.fetchMetricsCallCount == 1)
        
        let _ = try await monitor.fetchMetrics()
        #expect(mockService.fetchMetricsCallCount == 2)
        
        let _ = try await monitor.fetchMetrics()
        #expect(mockService.fetchMetricsCallCount == 3)
    }
    
    @Test("Mock service can be reset")
    func testMockReset() async throws {
        let mockService = MockPiMonitorService()
        mockService.shouldSucceed = false
        mockService.mockError = .malformedURL
        
        let environment = PiMonitorEnvironment(host: "reset.test")
        let monitor = PiMonitor(service: mockService, environment: environment)
        
        // First call should fail
        do {
            let _ = try await monitor.fetchMetrics()
            Issue.record("Should have thrown error")
        } catch {
            // Expected
        }
        
        #expect(mockService.fetchMetricsCallCount == 1)
        
        // Reset mock
        mockService.reset()
        
        #expect(mockService.fetchMetricsCallCount == 0)
        #expect(mockService.shouldSucceed == true)
        #expect(mockService.mockError == nil)
        
        // Now should succeed
        let metrics = try await monitor.fetchMetrics()
        #expect(metrics.socTemperature == 45.5)
        #expect(mockService.fetchMetricsCallCount == 1)
    }
}

