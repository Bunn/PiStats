//
//  PiholeV6ServiceTests.swift
//  PiStatsCoreTests
//
//  Created for testing PiholeV6Service
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("PiholeV6Service Tests", .serialized)
struct PiholeV6ServiceTests {
    
    // MARK: - Setup and Teardown
    
    private let mockSession: URLSession
    
    init() {
        // Setup mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }
    
    // MARK: - Authentication Tests
    
    @Test("authenticate succeeds with valid token")
    func testAuthenticateSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        var authRequestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                authRequestCount += 1
                #expect(request.httpMethod == "POST")
                #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json; charset=utf-8")
                
                // Verify request body contains password
                if let body = request.httpBody {
                    let json = try? JSONSerialization.jsonObject(with: body) as? [String: String]
                    #expect(json?["password"] == "test-token-v6")
                }
                
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                // For subsequent requests after auth
                let data = MockData.jsonData(from: MockData.v6SummaryJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        // This will trigger authentication
        let _ = try await service.fetchSummary()
        #expect(authRequestCount == 1)
        
        MockURLProtocol.reset()
    }
    
    @Test("authenticate throws on missing token")
    func testAuthenticateMissingToken() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6NoToken, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            throw PiholeServiceError.missingToken
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.fetchSummary()
        }
        
        MockURLProtocol.reset()
    }
    

    
    // MARK: - fetchSummary Tests
    
    @Test("fetchSummary returns correct summary data")
    func testFetchSummarySuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("stats/summary") == true {
                #expect(request.value(forHTTPHeaderField: "X-FTL-SID") == "test-session-id")
                #expect(request.value(forHTTPHeaderField: "X-FTL-CSRF") == "test-csrf-token")
                
                let data = MockData.jsonData(from: MockData.v6SummaryJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
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
    
    @Test("fetchSummary handles partial data gracefully")
    func testFetchSummaryPartialData() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let partialData: [String: Any] = [
                    "queries": [
                        "total": 5000,
                        "blocked": 1000
                        // Missing some fields
                    ],
                    "gravity": [:]
                ]
                let data = MockData.jsonData(from: partialData)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let summary = try await service.fetchSummary()
        
        #expect(summary.queries == 5000)
        #expect(summary.adsBlocked == 1000)
        #expect(summary.domainsBeingBlocked == 0) // Default value
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchStatus Tests
    
    @Test("fetchStatus returns enabled status")
    func testFetchStatusEnabled() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let status = try await service.fetchStatus()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchStatus returns disabled status")
    func testFetchStatusDisabled() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                let data = MockData.jsonData(from: MockData.v6StatusDisabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let status = try await service.fetchStatus()
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - fetchHistory Tests
    
    @Test("fetchHistory returns correct history data")
    func testFetchHistorySuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("history") == true {
                let data = MockData.jsonData(from: MockData.v6HistoryJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let history = try await service.fetchHistory()
        
        #expect(history.count == 3)
        #expect(history[0].blocked == 20)
        #expect(history[0].forwarded == 100) // forwarded + cached (80 + 20)
        #expect(history[1].blocked == 30)
        #expect(history[1].forwarded == 120) // forwarded + cached (100 + 20)
        
        MockURLProtocol.reset()
    }
    
    @Test("fetchHistory throws on invalid data")
    func testFetchHistoryInvalidData() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: ["history": "not an array"])
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.fetchHistory()
        }
        
        MockURLProtocol.reset()
    }
    
    // MARK: - enable Tests
    
    @Test("enable sets status to enabled")
    func testEnableSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                #expect(request.httpMethod == "POST")
                
                // Verify request body
                if let body = request.httpBody {
                    let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                    #expect(json?["blocking"] as? Bool == true)
                }
                
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let status = try await service.enable()
        #expect(status == .enabled)
        
        MockURLProtocol.reset()
    }
    
    // MARK: - disable Tests
    
    @Test("disable without timer sets status to disabled")
    func testDisableWithoutTimer() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                #expect(request.httpMethod == "POST")
                
                // Verify request body
                if let body = request.httpBody {
                    let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                    #expect(json?["blocking"] as? Bool == false)
                }
                
                let data = MockData.jsonData(from: MockData.v6StatusDisabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let status = try await service.disable(timer: nil)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable with timer includes timer value")
    func testDisableWithTimer() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                #expect(request.httpMethod == "POST")
                
                // Verify request body includes timer
                if let body = request.httpBody {
                    let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any]
                    #expect(json?["blocking"] as? Bool == false)
                    #expect(json?["timer"] as? Int == 300)
                }
                
                let data = MockData.jsonData(from: MockData.v6StatusDisabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            // Return error for unexpected requests
            throw PiholeServiceError.unknownError
        }
        
        let status = try await service.disable(timer: 300)
        #expect(status == .disabled)
        
        MockURLProtocol.reset()
    }
    
    @Test("disable throws on invalid response")
    func testDisableInvalidResponse() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: ["invalid": "response"])
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        await #expect(throws: PiholeServiceError.self) {
            try await service.disable(timer: nil)
        }
        
        MockURLProtocol.reset()
    }
}

