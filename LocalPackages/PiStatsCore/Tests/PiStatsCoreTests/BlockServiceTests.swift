//
//  BlockServiceTests.swift
//  PiStatsCoreTests
//
//  Tests for block-whole-service (regex deny rules) and the service catalog.
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("Block Service Tests", .serialized)
struct BlockServiceTests {
    private let mockSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }

    @Test("BlockableService.isBlocked requires every rule present")
    func testIsBlocked() {
        let service = BlockableService(id: "t", name: "T", systemImage: "x", rules: ["a", "b"])
        #expect(service.isBlocked(in: ["a", "b", "c"]) == true)
        #expect(service.isBlocked(in: ["a"]) == false)
        #expect(service.isBlocked(in: []) == false)
        #expect(BlockableService.catalog.isEmpty == false)
        #expect(BlockableService.catalog.allSatisfy { !$0.rules.isEmpty })
    }

    @Test("v6 fetchDenyRegexRules parses rule strings")
    func testV6FetchDenyRegex() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("domains/deny/regex") == true {
                let json: [String: Any] = ["domains": [
                    ["domain": #"(\.|^)tiktok\.com$"#, "kind": "regex", "type": "deny", "enabled": true]
                ]]
                return MockURLProtocol.successResponse(for: request, data: try JSONSerialization.data(withJSONObject: json))
            }
            throw PiholeServiceError.unknownError
        }

        let rules = try await service.fetchDenyRegexRules()
        #expect(rules == [#"(\.|^)tiktok\.com$"#])

        MockURLProtocol.reset()
    }

    @Test("v6 addDenyRegexRules POSTs the rules as a domain array")
    func testV6AddDenyRegex() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var posted = false

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("domains/deny/regex") == true {
                #expect(request.httpMethod == "POST")
                if let body = request.httpBody,
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    #expect((json["domain"] as? [String])?.contains(#"(\.|^)x\.com$"#) == true)
                }
                posted = true
                return MockURLProtocol.successResponse(for: request, data: Data("{}".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        try await service.addDenyRegexRules([#"(\.|^)x\.com$"#])
        #expect(posted)

        MockURLProtocol.reset()
    }

    @Test("v6 removeDenyRegexRules issues a DELETE per rule")
    func testV6RemoveDenyRegex() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var deleteCount = 0

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("domains/deny/regex") == true {
                #expect(request.httpMethod == "DELETE")
                deleteCount += 1
                return MockURLProtocol.successResponse(for: request, data: nil, statusCode: 204)
            }
            throw PiholeServiceError.unknownError
        }

        try await service.removeDenyRegexRules([#"(\.|^)a\.com$"#, #"(\.|^)b\.com$"#])
        #expect(deleteCount == 2)

        MockURLProtocol.reset()
    }

    @Test("v5 deny regex operations are not supported")
    func testV5NotSupported() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)

        do { _ = try await service.fetchDenyRegexRules(); Issue.record("expected notSupported") }
        catch PiholeServiceError.notSupported {}
        do { try await service.addDenyRegexRules(["a"]); Issue.record("expected notSupported") }
        catch PiholeServiceError.notSupported {}
        do { try await service.removeDenyRegexRules(["a"]); Issue.record("expected notSupported") }
        catch PiholeServiceError.notSupported {}

        MockURLProtocol.reset()
    }
}
