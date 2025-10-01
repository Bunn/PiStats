//
//  PiMonitorServiceTests.swift
//  PiStatsCoreTests
//
//  Created for testing PiMonitorService
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("PiMonitorService Tests", .serialized)
struct PiMonitorServiceTests {
    
    private let mockSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }
    
    // MARK: - fetchMetrics Tests
    
    @Test("fetchMetrics succeeds with valid response")
    func testFetchMetricsSuccess() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.path == "/monitor.json")
            #expect(request.url?.scheme == "http")
            #expect(request.url?.host == "192.168.1.100")
            #expect(request.url?.port == 8088)
            #expect(request.httpMethod == "GET")
            
            let data = MockData.piMonitorMetricsJSON
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, timeoutInterval: 30, secure: false, urlSession: mockSession)
        let metrics = try await monitor.fetchMetrics()
        
        #expect(metrics.socTemperature == 45.5)
        #expect(metrics.uptime == 86400.0)
        #expect(metrics.loadAverage == [0.5, 0.6, 0.7])
        #expect(metrics.kernelRelease == "5.10.0-rpi1")
        #expect(metrics.memory.totalMemory == 4096000)
        #expect(metrics.memory.freeMemory == 2048000)
        #expect(metrics.memory.availableMemory == 3072000)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics uses default port when not specified")
    func testFetchMetricsDefaultPort() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.port == nil) // Default port not in URL
            
            let data = MockData.piMonitorMetricsJSON
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", timeoutInterval: 30, secure: false, urlSession: mockSession)
        let _ = try await monitor.fetchMetrics()
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics uses https when secure is true")
    func testFetchMetricsSecure() async throws {
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.scheme == "https")
            
            let data = MockData.piMonitorMetricsJSON
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, timeoutInterval: 30, secure: true, urlSession: mockSession)
        let _ = try await monitor.fetchMetrics()
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics handles completion callback")
    func testFetchMetricsCallback() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = MockData.piMonitorMetricsJSON
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, urlSession: mockSession)
        
        await withCheckedContinuation { continuation in
            monitor.fetchMetrics { result in
                switch result {
                case .success(let metrics):
                    #expect(metrics.socTemperature == 45.5)
                    continuation.resume()
                case .failure(let error):
                    Issue.record("Should not fail: \(error)")
                    continuation.resume()
                }
            }
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics throws on invalid JSON")
    func testFetchMetricsInvalidJSON() async throws {
        MockURLProtocol.requestHandler = { request in
            let invalidData = "Invalid JSON".data(using: .utf8)!
            return MockURLProtocol.successResponse(for: request, data: invalidData)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, urlSession: mockSession)
        
        await withCheckedContinuation { continuation in
            monitor.fetchMetrics { result in
                switch result {
                case .success:
                    Issue.record("Should have failed")
                    continuation.resume()
                case .failure(let error):
                    if case .invalidDecode = error {
                        // Expected error
                    } else {
                        Issue.record("Wrong error type: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics throws on network error")
    func testFetchMetricsNetworkError() async throws {
        MockURLProtocol.requestHandler = { request in
            throw TestHelpers.createNetworkError()
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, urlSession: mockSession)
        
        await withCheckedContinuation { continuation in
            monitor.fetchMetrics { result in
                switch result {
                case .success:
                    Issue.record("Should have failed")
                    continuation.resume()
                case .failure(let error):
                    if case .sessionError = error {
                        // Expected error
                    } else {
                        Issue.record("Wrong error type: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics throws on invalid response code")
    func testFetchMetricsInvalidResponseCode() async throws {
        MockURLProtocol.requestHandler = { request in
            let data = MockData.piMonitorMetricsJSON
            return MockURLProtocol.successResponse(for: request, data: data, statusCode: 500)
        }
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, urlSession: mockSession)
        
        await withCheckedContinuation { continuation in
            monitor.fetchMetrics { result in
                switch result {
                case .success:
                    Issue.record("Should have failed")
                    continuation.resume()
                case .failure(let error):
                    if case .invalidResponseCode(let code) = error {
                        #expect(code == 500)
                    } else {
                        Issue.record("Wrong error type: \(error)")
                    }
                    continuation.resume()
                }
            }
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchMetrics respects timeout interval")
    func testFetchMetricsTimeout() {
        var service = PiMonitorService()
        service.timeoutInterval = 10
        
        #expect(service.timeoutInterval == 10)
        
        let monitor = PiMonitor(host: "192.168.1.100", port: 8088, timeoutInterval: 20)
        #expect(monitor.timeoutInterval == 20)
    }
}

