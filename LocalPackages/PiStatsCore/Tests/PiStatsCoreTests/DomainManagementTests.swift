//
//  DomainManagementTests.swift
//  PiStatsCoreTests
//
//  Tests for generic allow/deny domain management (exact + regex).
//

import Testing
import Foundation
@testable import PiStatsCore

extension MockNetworkTests {
@Suite("Domain Management Tests", .serialized)
struct DomainManagementTests {
    private let mockSession: URLSession

    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
    }

    /// URLSession hands the request body to URLProtocol via `httpBodyStream`,
    /// not `httpBody`, so read whichever is populated.
    private static func httpBody(from request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    @Test("v6 fetchDomains parses rules for a given type/kind")
    func testV6FetchDomains() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("auth") {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if url.contains("domains/allow/exact") {
                let json: [String: Any] = ["domains": [
                    ["domain": "example.com", "kind": "exact", "type": "allow", "enabled": true, "comment": "ok", "groups": [0]]
                ]]
                return MockURLProtocol.successResponse(for: request, data: try JSONSerialization.data(withJSONObject: json))
            }
            throw PiholeServiceError.unknownError
        }

        let rules = try await service.fetchDomains(type: .allow, kind: .exact)
        #expect(rules.count == 1)
        #expect(rules.first?.domain == "example.com")
        #expect(rules.first?.type == .allow)
        #expect(rules.first?.kind == .exact)
        #expect(rules.first?.enabled == true)
        #expect(rules.first?.comment == "ok")

        MockURLProtocol.reset()
    }

    @Test("v6 addDomains POSTs to the correct type/kind path with the domain array")
    func testV6AddDomains() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var postedToDenyExact = false
        var postedDomains: [String]?

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("auth") {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if url.contains("domains/deny/exact") {
                #expect(request.httpMethod == "POST")
                postedToDenyExact = true
                if let body = Self.httpBody(from: request),
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    postedDomains = json["domain"] as? [String]
                }
                return MockURLProtocol.successResponse(for: request, data: Data("{}".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        try await service.addDomains([
            DomainRule(domain: "ads.example.com", type: .deny, kind: .exact, enabled: true, comment: "x", groups: [0])
        ])
        #expect(postedToDenyExact)
        #expect(postedDomains?.contains("ads.example.com") == true)

        MockURLProtocol.reset()
    }

    @Test("v6 addDomains groups mixed buckets into separate POSTs")
    func testV6AddDomainsGroupsByBucket() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var postedPaths: [String] = []

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("auth") {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if request.httpMethod == "POST" {
                postedPaths.append(url)
                return MockURLProtocol.successResponse(for: request, data: Data("{}".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        try await service.addDomains([
            DomainRule(domain: "a.com", type: .allow, kind: .exact),
            DomainRule(domain: #"(\.|^)b\.com$"#, type: .deny, kind: .regex)
        ])
        #expect(postedPaths.count == 2)
        #expect(postedPaths.contains { $0.contains("domains/allow/exact") })
        #expect(postedPaths.contains { $0.contains("domains/deny/regex") })

        MockURLProtocol.reset()
    }

    @Test("v6 removeDomains issues a DELETE per domain at its bucket path")
    func testV6RemoveDomains() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var deleteCount = 0

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("auth") {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if url.contains("domains/allow/regex") {
                #expect(request.httpMethod == "DELETE")
                deleteCount += 1
                return MockURLProtocol.successResponse(for: request, data: nil, statusCode: 204)
            }
            throw PiholeServiceError.unknownError
        }

        try await service.removeDomains([
            DomainRule(domain: #"(\.|^)a\.com$"#, type: .allow, kind: .regex),
            DomainRule(domain: #"(\.|^)b\.com$"#, type: .allow, kind: .regex)
        ])
        #expect(deleteCount == 2)

        MockURLProtocol.reset()
    }

    @Test("v6 setDomain PUTs the enabled state to the domain path")
    func testV6SetDomainEnabled() async throws {
        let service = PiholeV6Service(MockData.testPiholeV6, urlSession: mockSession)
        var putToPath = false
        var putEnabled: Bool?

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            if url.contains("auth") {
                return MockURLProtocol.successResponse(for: request, data: MockData.jsonData(from: MockData.v6AuthSuccessJSON))
            } else if url.contains("domains/deny/exact/ads.example.com") {
                #expect(request.httpMethod == "PUT")
                putToPath = true
                if let body = Self.httpBody(from: request),
                   let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    putEnabled = json["enabled"] as? Bool
                }
                return MockURLProtocol.successResponse(for: request, data: Data("{}".utf8))
            }
            throw PiholeServiceError.unknownError
        }

        let rule = DomainRule(domain: "ads.example.com", type: .deny, kind: .exact, enabled: true, comment: "x", groups: [0])
        try await service.setDomain(rule, enabled: false)
        #expect(putToPath)
        #expect(putEnabled == false)

        MockURLProtocol.reset()
    }
}
}
