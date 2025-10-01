//
//  PiholeV5ServiceTests.swift
//  PiStatsCoreTests
//
//  Created for testing PiholeV5Service
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("PiholeV5Service Tests", .serialized)
struct PiholeV5ServiceTests {
    
    // MARK: - Setup and Teardown
    
    private let mockSession: URLSession
    
    init() {
        // Setup mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }
    
    // MARK: - fetchSummary Tests
    
    @Test("fetchSummary returns correct summary data")
    func testFetchSummarySuccess() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("summaryRaw") == true)
            #expect(request.url?.absoluteString.contains("auth=test-token-v5") == true)
            
            let data = MockData.jsonData(from: MockData.v5SummaryJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let summary = try await service.fetchSummary()
        
        #expect(summary.domainsBeingBlocked == 150000)
        #expect(summary.queries == 5000)
        #expect(summary.adsBlocked == 1000)
        #expect(summary.adsPercentageToday == 20.0)
        #expect(summary.uniqueDomains == 500)
        #expect(summary.queriesForwarded == 3000)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchSummary handles missing fields gracefully")
    func testFetchSummaryPartialData() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let partialData: [String: Any] = [
                "domains_being_blocked": 100000,
                "dns_queries_today": 2000
                // Missing other fields
            ]
            let data = MockData.jsonData(from: partialData)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let summary = try await service.fetchSummary()
        
        #expect(summary.domainsBeingBlocked == 100000)
        #expect(summary.queries == 2000)
        #expect(summary.adsBlocked == 0) // Default value
        #expect(summary.adsPercentageToday == 0.0) // Default value
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchSummary throws on invalid JSON")
    func testFetchSummaryInvalidJSON() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let invalidData = "Invalid JSON".data(using: .utf8)!
            return MockURLProtocol.successResponse(for: request, data: invalidData)
        }
        
        await #expect(throws: Error.self) {
            try await service.fetchSummary()
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchSummary throws on network error")
    func testFetchSummaryNetworkError() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            throw TestHelpers.createNetworkError()
        }
        
        await #expect(throws: Error.self) {
            try await service.fetchSummary()
        }
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchStatus Tests
    
    @Test("fetchStatus returns enabled status")
    func testFetchStatusEnabled() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("status") == true)
            
            let data = MockData.jsonData(from: MockData.v5StatusEnabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.fetchStatus()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus returns disabled status")
    func testFetchStatusDisabled() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let data = MockData.jsonData(from: MockData.v5StatusDisabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.fetchStatus()
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus returns unknown for invalid status")
    func testFetchStatusUnknown() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let data = MockData.jsonData(from: ["status": "invalid_status"])
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.fetchStatus()
        #expect(status == .unknown)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus throws when status key missing")
    func testFetchStatusMissingKey() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let data = MockData.jsonData(from: ["other_key": "value"])
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.fetchStatus()
        }
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchHistory Tests
    
    @Test("fetchHistory returns correct history data")
    func testFetchHistorySuccess() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("overTimeData10mins") == true)
            
            let data = MockData.jsonData(from: MockData.v5HistoryJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let history = try await service.fetchHistory()
        
        #expect(history.count == 3)

        MockURLProtocol.reset()
    }
    
    @Test("fetchHistory throws on missing data")
    func testFetchHistoryMissingData() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let data = MockData.jsonData(from: ["domains_over_time": [:]])
            // Missing ads_over_time
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.fetchHistory()
        }
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchHistory handles empty history")
    func testFetchHistoryEmpty() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let emptyHistory: [String: Any] = [
                "domains_over_time": [:],
                "ads_over_time": [:]
            ]
            let data = MockData.jsonData(from: emptyHistory)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let history = try await service.fetchHistory()
        #expect(history.isEmpty)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - enable Tests
    
    @Test("enable sets status to enabled")
    func testEnableSuccess() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString.contains("enable") == true)
            #expect(request.url?.absoluteString.contains("auth=test-token-v5") == true)
            
            let data = MockData.jsonData(from: MockData.v5StatusEnabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.enable()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - disable Tests
    
    @Test("disable without timer sets status to disabled")
    func testDisableWithoutTimer() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString.contains("disable") == true)
            #expect(request.url?.absoluteString.contains("auth=test-token-v5") == true)
            
            let data = MockData.jsonData(from: MockData.v5StatusDisabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.disable(timer: nil)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable with timer includes timer value")
    func testDisableWithTimer() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.url?.absoluteString.contains("disable=300") == true)
            #expect(request.url?.absoluteString.contains("auth=test-token-v5") == true)
            
            let data = MockData.jsonData(from: MockData.v5StatusDisabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await service.disable(timer: 300)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable throws on invalid response")
    func testDisableInvalidResponse() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            let data = MockData.jsonData(from: ["invalid": "response"])
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.disable(timer: nil)
        }
        
        MockURLProtocol.reset()
    }
}

