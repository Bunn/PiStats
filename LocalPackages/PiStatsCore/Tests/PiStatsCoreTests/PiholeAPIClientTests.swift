//
//  PiholeAPIClientTests.swift
//  PiStatsCoreTests
//
//  Created for testing PiholeAPIClient
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("PiholeAPIClient Tests", .serialized)
struct PiholeAPIClientTests {
    
    private let mockSession: URLSession
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }


    // MARK: - Initialization Tests
    
    @Test("initializes with V5 service for V5 pihole")
    func testInitializeWithV5() {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        #expect(client.pihole.version == .v5)
        #expect(client.pihole.name == "Test Pi-hole V5")
    }
    
    @Test("initializes with V6 service for V6 pihole")
    func testInitializeWithV6() {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        #expect(client.pihole.version == .v6)
        #expect(client.pihole.name == "Test Pi-hole V6")
    }
    
    // MARK: - V5 Service Routing Tests
    
    @Test("fetchSummary routes to V5 service correctly")
    func testV5FetchSummary() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // V5 specific endpoint
            #expect(request.url?.absoluteString.contains("summaryRaw") == true)
            #expect(request.url?.absoluteString.contains("admin/api.php") == true)
            
            let data = MockData.jsonData(from: MockData.v5SummaryJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let summary = try await client.fetchSummary()
        #expect(summary.domainsBeingBlocked == 150000)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus routes to V5 service correctly")
    func testV5FetchStatus() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("status") == true)
            #expect(request.url?.absoluteString.contains("admin/api.php") == true)
            
            let data = MockData.jsonData(from: MockData.v5StatusEnabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await client.fetchStatus()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("enable routes to V5 service correctly")
    func testV5Enable() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("enable") == true)
            #expect(request.httpMethod == "POST")
            
            let data = MockData.jsonData(from: MockData.v5StatusEnabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await client.enable()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable routes to V5 service correctly")
    func testV5Disable() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("disable") == true)
            #expect(request.httpMethod == "POST")
            
            let data = MockData.jsonData(from: MockData.v5StatusDisabledJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let status = try await client.disable(timer: nil)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - V6 Service Routing Tests
    
    @Test("fetchSummary routes to V6 service correctly")
    func testV6FetchSummary() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                // V6 specific endpoint
                #expect(request.url?.absoluteString.contains("api/stats/summary") == true)
                
                let data = MockData.jsonData(from: MockData.v6SummaryJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let summary = try await client.fetchSummary()
        #expect(summary.domainsBeingBlocked == 150000)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus routes to V6 service correctly")
    func testV6FetchStatus() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                #expect(request.url?.absoluteString.contains("api/dns/blocking") == true)
                
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let status = try await client.fetchStatus()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("enable routes to V6 service correctly")
    func testV6Enable() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                #expect(request.url?.absoluteString.contains("api/dns/blocking") == true)
                #expect(request.httpMethod == "POST")
                
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let status = try await client.enable()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable routes to V6 service correctly")
    func testV6Disable() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                #expect(request.url?.absoluteString.contains("api/dns/blocking") == true)
                #expect(request.httpMethod == "POST")
                
                let data = MockData.jsonData(from: MockData.v6StatusDisabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let status = try await client.disable(timer: 300)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchHistory Tests
    
    @Test("fetchHistory routes to V5 service correctly")
    func testV5FetchHistory() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            #expect(request.url?.absoluteString.contains("overTimeData10mins") == true)
            
            let data = MockData.jsonData(from: MockData.v5HistoryJSON)
            return MockURLProtocol.successResponse(for: request, data: data)
        }
        
        let history = try await client.fetchHistory()
        #expect(history.count == 3)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchHistory routes to V6 service correctly")
    func testV6FetchHistory() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                #expect(request.url?.absoluteString.contains("api/history") == true)
                
                let data = MockData.jsonData(from: MockData.v6HistoryJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let history = try await client.fetchHistory()
        #expect(history.count == 3)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchMonitorMetrics Tests
    
    @Test("fetchMonitorMetrics throws when piMonitor not configured")
    func testFetchMonitorMetricsNoPiMonitor() async throws {
        let client = PiholeAPIClient(MockData.testPiholeV5NoPiMonitor, urlSession: mockSession)
        
        do {
            let _ = try await client.fetchMonitorMetrics()
            Issue.record("Should have thrown error")
        } catch let error as PiholeServiceError {
            if case .piMonitorNotSet = error {
                // Expected error
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

