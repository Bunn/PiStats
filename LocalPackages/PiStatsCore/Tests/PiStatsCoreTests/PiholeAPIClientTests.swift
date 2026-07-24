//
//  PiholeAPIClientTests.swift
//  PiStatsCoreTests
//

import Foundation
import Testing
@testable import PiStatsCore

extension MockNetworkTests {
    @Suite("PiholeAPIClient Tests", .serialized)
    struct PiholeAPIClientTests {
        private let mockSession: URLSession

        init() {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [MockURLProtocol.self]
            mockSession = URLSession(configuration: configuration)
        }

        @Test("initializes the Pi-hole 6 service")
        func initializesService() {
            let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)
            #expect(client.pihole.name == "Test Pi-hole V6")
        }

        @Test("fetchSummary uses the Pi-hole 6 endpoint")
        func fetchSummary() async throws {
            let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)

            MockURLProtocol.requestHandler = { request in
                if request.url?.absoluteString.contains("auth") == true {
                    return MockURLProtocol.successResponse(
                        for: request,
                        data: MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                    )
                }

                #expect(request.url?.absoluteString.contains("api/stats/summary") == true)
                return MockURLProtocol.successResponse(
                    for: request,
                    data: MockData.jsonData(from: MockData.v6SummaryJSON)
                )
            }

            let summary = try await client.fetchSummary()
            #expect(summary.domainsBeingBlocked == 150_000)
            MockURLProtocol.reset()
        }

        @Test("fetchStatus uses the Pi-hole 6 endpoint")
        func fetchStatus() async throws {
            let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)

            MockURLProtocol.requestHandler = { request in
                if request.url?.absoluteString.contains("auth") == true {
                    return MockURLProtocol.successResponse(
                        for: request,
                        data: MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                    )
                }

                #expect(request.url?.absoluteString.contains("api/dns/blocking") == true)
                return MockURLProtocol.successResponse(
                    for: request,
                    data: MockData.jsonData(from: MockData.v6StatusEnabledJSON)
                )
            }

            #expect(try await client.fetchStatus() == .enabled)
            MockURLProtocol.reset()
        }

        @Test("fetchHistory uses the Pi-hole 6 endpoint")
        func fetchHistory() async throws {
            let client = PiholeAPIClient(MockData.testPiholeV6, urlSession: mockSession)

            MockURLProtocol.requestHandler = { request in
                if request.url?.absoluteString.contains("auth") == true {
                    return MockURLProtocol.successResponse(
                        for: request,
                        data: MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                    )
                }

                #expect(request.url?.absoluteString.contains("api/history") == true)
                return MockURLProtocol.successResponse(
                    for: request,
                    data: MockData.jsonData(from: MockData.v6HistoryJSON)
                )
            }

            #expect(try await client.fetchHistory().count == 3)
            MockURLProtocol.reset()
        }
    }
}
