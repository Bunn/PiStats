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
    
    // MARK: - fetchTopDomains Tests

    @Test("fetchTopDomains returns correct data with auth and parallel requests")
    func testFetchTopDomainsSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("stats/top_domains") == true {
                // Check if it's the blocked or permitted request
                if request.url?.absoluteString.contains("blocked=true") == true {
                    let data = MockData.jsonData(from: MockData.v6TopDomainsBlockedJSON)
                    return MockURLProtocol.successResponse(for: request, data: data)
                } else {
                    let data = MockData.jsonData(from: MockData.v6TopDomainsPermittedJSON)
                    return MockURLProtocol.successResponse(for: request, data: data)
                }
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchTopDomains(count: 10)

        #expect(result.topPermitted.count == 3)
        #expect(result.topBlocked.count == 3)

        #expect(result.topPermitted[0].domain == "google.com")
        #expect(result.topPermitted[0].count == 500)

        #expect(result.topBlocked[0].domain == "ads.doubleclick.net")
        #expect(result.topBlocked[0].count == 1200)

        MockURLProtocol.reset()
    }

    @Test("fetchTopDomains handles empty response")
    func testFetchTopDomainsEmpty() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("stats/top_domains") == true {
                let emptyData: [String: Any] = ["domains": []]
                let data = MockData.jsonData(from: emptyData)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchTopDomains(count: 10)

        #expect(result.topPermitted.isEmpty)
        #expect(result.topBlocked.isEmpty)

        MockURLProtocol.reset()
    }

    // MARK: - fetchTopClients Tests

    @Test("fetchTopClients returns correct data with auth and parallel requests")
    func testFetchTopClientsSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("stats/top_clients") == true {
                if request.url?.absoluteString.contains("blocked=true") == true {
                    let data = MockData.jsonData(from: MockData.v6TopClientsBlockedJSON)
                    return MockURLProtocol.successResponse(for: request, data: data)
                } else {
                    let data = MockData.jsonData(from: MockData.v6TopClientsActiveJSON)
                    return MockURLProtocol.successResponse(for: request, data: data)
                }
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchTopClients(count: 10)

        #expect(result.topActive.count == 3)
        #expect(result.topBlocked.count == 3)

        // Verify active clients
        #expect(result.topActive[0].name == "MacBook-Pro")
        #expect(result.topActive[0].ip == "192.168.1.100")
        #expect(result.topActive[0].count == 5000)

        // Verify empty name client uses IP
        #expect(result.topActive[2].name == "")
        #expect(result.topActive[2].ip == "192.168.1.150")

        // Verify blocked clients
        #expect(result.topBlocked[0].name == "IoT-Camera")
        #expect(result.topBlocked[0].ip == "192.168.1.200")
        #expect(result.topBlocked[0].count == 2400)

        MockURLProtocol.reset()
    }

    @Test("fetchTopClients handles empty response")
    func testFetchTopClientsEmpty() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("stats/top_clients") == true {
                let emptyData: [String: Any] = ["clients": []]
                let data = MockData.jsonData(from: emptyData)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchTopClients(count: 10)

        #expect(result.topActive.isEmpty)
        #expect(result.topBlocked.isEmpty)

        MockURLProtocol.reset()
    }

    // MARK: - fetchQueryTypes Tests

    @Test("fetchQueryTypes converts counts to sorted percentages")
    func testFetchQueryTypesSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("stats/query_types") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6QueryTypesJSON))
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchQueryTypes()

        // Zero-count types are dropped; remaining are sorted descending.
        #expect(result.types.count == 3)
        #expect(result.types[0].name == "A")
        #expect(result.types[0].percentage == 60)
        #expect(result.types[1].name == "AAAA")
        #expect(result.types[1].percentage == 30)
        #expect(result.types[2].name == "HTTPS")
        #expect(result.types[2].percentage == 10)

        MockURLProtocol.reset()
    }

    @Test("fetchQueryTypes throws on invalid data")
    func testFetchQueryTypesInvalidData() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            }
            return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: ["types": "not an object"]))
        }

        await #expect(throws: PiholeServiceError.self) {
            try await service.fetchQueryTypes()
        }

        MockURLProtocol.reset()
    }

    // MARK: - fetchUpstreams Tests

    @Test("fetchUpstreams returns sorted percentages with display names")
    func testFetchUpstreamsSuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("stats/upstreams") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6UpstreamsJSON))
            }
            throw PiholeServiceError.unknownError
        }

        let result = try await service.fetchUpstreams()

        #expect(result.upstreams.count == 3)
        #expect(result.upstreams[0].displayName == "dns.google")
        #expect(result.upstreams[0].percentage == 60)
        // Empty name falls back to IP.
        #expect(result.upstreams[1].displayName == "1.1.1.1")
        #expect(result.upstreams[1].percentage == 30)
        // Cache pseudo-upstream has no IP, displays its name.
        #expect(result.upstreams[2].displayName == "cache")
        #expect(result.upstreams[2].percentage == 10)

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
    
    // MARK: - URL Construction Tests
    
    @Test("makeURL uses HTTP scheme by default")
    func testMakeURLHTTPScheme() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Verify the URL uses HTTP scheme
            #expect(request.url?.scheme == "http")
            #expect(request.url?.host == "192.168.1.101")
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
    
    @Test("makeURL uses HTTPS scheme when secure is true")
    func testMakeURLHTTPSScheme() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6HTTPS, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Verify the URL uses HTTPS scheme
            #expect(request.url?.scheme == "https")
            #expect(request.url?.host == "pihole.example.com")
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
    
    @Test("makeURL includes custom port in URL")
    func testMakeURLCustomPort() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6CustomPort, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Verify the URL includes the custom port
            #expect(request.url?.scheme == "http")
            #expect(request.url?.port == 8080)
            #expect(request.url?.host == "192.168.1.105")
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
    
    @Test("makeURL uses HTTPS with custom port")
    func testMakeURLHTTPSCustomPort() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6HTTPSCustomPort, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Verify the URL uses HTTPS with custom port
            #expect(request.url?.scheme == "https")
            #expect(request.url?.port == 8443)
            #expect(request.url?.host == "pihole.example.com")
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
    
    @Test("makeURL includes correct API path")
    func testMakeURLAPIPath() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        var authURL: URL?
        var blockingURL: URL?
        
        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                authURL = request.url
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("dns/blocking") == true {
                blockingURL = request.url
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            throw PiholeServiceError.unknownError
        }
        
        let _ = try await service.fetchStatus()
        
        // Verify auth URL path
        #expect(authURL?.path == "/api/auth" || authURL?.path(percentEncoded: false) == "/api/auth")
        
        // Verify blocking URL path
        #expect(blockingURL?.path == "/api/dns/blocking" || blockingURL?.path(percentEncoded: false) == "/api/dns/blocking")
        
        MockURLProtocol.reset()
    }
    
    @Test("makeURL includes port 80 for HTTP")
    func testMakeURLPort80ForHTTP() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Port 80 should be included in the URL
            #expect(request.url?.port == 80)
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
    
    @Test("makeURL includes port 443 for HTTPS")
    func testMakeURLPort443ForHTTPS() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6HTTPS, urlSession: mockSession)
        
        MockURLProtocol.requestHandler = { request in
            // Port 443 should be included in the URL
            #expect(request.url?.port == 443)
            
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else {
                let data = MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
        }
        
        let _ = try await service.fetchStatus()
        MockURLProtocol.reset()
    }
}

