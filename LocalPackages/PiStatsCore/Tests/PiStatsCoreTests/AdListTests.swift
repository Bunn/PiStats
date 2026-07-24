//
//  AdListTests.swift
//  PiStatsCoreTests
//
//  Tests for adlist (blocklist) listing and enable/disable.
//

import Testing
import Foundation
@testable import PiStatsCore

extension MockNetworkTests {
@Suite("AdList Tests", .serialized)
struct AdListTests {
    private let mockSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }

    @Test("v6 fetchAdlists parses block + allow lists")
    func testV6FetchAdlists() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("lists") == true {
                let json: [String: Any] = ["lists": [
                    ["id": 1, "address": "https://example.com/block.txt", "type": "block", "enabled": true, "comment": "main", "groups": [0]],
                    ["id": 2, "address": "https://example.com/allow.txt", "type": "allow", "enabled": false, "comment": NSNull(), "groups": [0]]
                ]]
                let data = try JSONSerialization.data(withJSONObject: json)
                return MockURLProtocol.successResponse(for: request, data: data)
            }
            throw PiholeServiceError.unknownError
        }

        let lists = try await service.fetchAdlists()
        #expect(lists.count == 2)
        #expect(lists.first?.address == "https://example.com/block.txt")
        #expect(lists.first?.enabled == true)
        #expect(lists.first?.isBlocklist == true)
        #expect(lists.first?.comment == "main")
        #expect(lists.last?.enabled == false)
        #expect(lists.last?.type == "allow")

        MockURLProtocol.reset()
    }

    @Test("v6 setAdlist PUTs the toggled list with type query")
    func testV6SetAdlistDisable() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        let adlist = AdList(id: 1, address: "https://example.com/block.txt", enabled: true,
                            type: "block", comment: "main", groups: [0])
        var putRequested = false

        MockURLProtocol.requestHandler = { request in
            if request.url?.absoluteString.contains("auth") == true {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.url?.absoluteString.contains("lists/") == true {
                #expect(request.httpMethod == "PUT")
                #expect(request.url?.absoluteString.contains("type=block") == true)
                if let body = request.httpBody,
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    #expect(json["enabled"] as? Bool == false)
                    #expect(json["type"] as? String == "block")
                }
                putRequested = true
                return MockURLProtocol.successResponse(for: request, data: Data("{}".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        try await service.setAdlist(adlist, enabled: false)
        #expect(putRequested)

        MockURLProtocol.reset()
    }

    @Test("v5 adlist operations are not supported")
    func testV5AdlistsNotSupported() async throws {
        let service = PiholeV5Service(MockData.testPiholeV5, urlSession: mockSession)

        do {
            _ = try await service.fetchAdlists()
            Issue.record("Expected fetchAdlists to throw notSupported on v5")
        } catch PiholeServiceError.notSupported {
            // expected
        }

        do {
            try await service.setAdlist(AdList(id: 0, address: "x", enabled: true, type: "block", comment: nil, groups: []), enabled: false)
            Issue.record("Expected setAdlist to throw notSupported on v5")
        } catch PiholeServiceError.notSupported {
            // expected
        }

        MockURLProtocol.reset()
    }
}
}
