//
//  GravityTests.swift
//  PiStatsCoreTests
//
//  Tests for the gravity (blocklist) update action.
//

import Testing
import Foundation
@testable import PiStatsCore

extension MockNetworkTests {
@Suite("Gravity Tests", .serialized)
struct GravityTests {
    private let mockSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }

    @Test("v6 updateGravity POSTs to action/gravity and succeeds on 2xx")
    func testV6UpdateGravitySuccess() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var gravityRequested = false

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            } else if request.url?.absoluteString.contains("action/gravity") == true {
                #expect(request.httpMethod == "POST")
                gravityRequested = true
                // Real gravity streams a progress log; only the 2xx status matters.
                return MockURLProtocol.successResponse(for: request, data: Data("[i] Updating gravity".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        try await service.updateGravity()
        #expect(gravityRequested)

        MockURLProtocol.reset()
    }

    @Test("v6 updateGravity throws on a server error")
    func testV6UpdateGravityServerError() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                let data = MockData.jsonData(from: MockData.v6AuthSuccessJSON)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            return MockURLProtocol.errorResponse(for: request, statusCode: 500)
        }

        await #expect(throws: PiholeServiceError.self) {
            try await service.updateGravity()
        }

        MockURLProtocol.reset()
    }

    @Test("v5 updateGravity is not supported")
    func testV5UpdateGravityNotSupported() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)

        do {
            try await service.updateGravity()
            Issue.record("Expected updateGravity to throw notSupported on v5")
        } catch PiholeServiceError.notSupported {
            // expected
        }

        MockURLProtocol.reset()
    }

    @Test("v6 fetchGravityLastUpdated returns the most recent adlist date_updated")
    func testV6GravityLastUpdated() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("lists") == true {
                let json: [String: Any] = ["lists": [
                    ["id": 1, "address": "a", "type": "block", "enabled": true, "groups": [0], "date_updated": 1_700_000_000],
                    ["id": 2, "address": "b", "type": "block", "enabled": true, "groups": [0], "date_updated": 1_700_500_000]
                ]]
                return MockURLProtocol.successResponse(for: request, data: try JSONSerialization.data(withJSONObject: json))
            }
            throw PiholeServiceError.unknownError
        }

        let date = try await service.fetchGravityLastUpdated()
        #expect(date == Date(timeIntervalSince1970: 1_700_500_000))

        MockURLProtocol.reset()
    }
}
}
