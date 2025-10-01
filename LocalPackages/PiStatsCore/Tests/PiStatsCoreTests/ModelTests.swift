//
//  ModelTests.swift
//  PiStatsCoreTests
//
//  Created for testing model types
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("Model Tests")
struct ModelTests {
    
    // MARK: - Pihole Tests
    
    @Test("Pihole initializes with correct values")
    func testPiholeInitialization() {
        let uuid = UUID()
        let piMonitor = PiMonitorEnvironment(host: "192.168.1.100", port: 8088, secure: false)
        
        let pihole = Pihole(
            name: "Test Pi-hole",
            address: "192.168.1.100",
            version: .v6,
            port: 80,
            token: "test-token",
            piMonitor: piMonitor,
            uuid: uuid
        )
        
        #expect(pihole.name == "Test Pi-hole")
        #expect(pihole.address == "192.168.1.100")
        #expect(pihole.version == .v6)
        #expect(pihole.port == 80)
        #expect(pihole.token == "test-token")
        #expect(pihole.piMonitor?.host == "192.168.1.100")
        #expect(pihole.uuid == uuid)
        #expect(pihole.id == uuid)
    }
    
    @Test("Pihole uses default values")
    func testPiholeDefaults() {
        let pihole = Pihole(name: "Test", address: "192.168.1.100")
        
        #expect(pihole.version == .v6)
        #expect(pihole.port == 80)
        #expect(pihole.token == nil)
        #expect(pihole.piMonitor == nil)
    }
    
    // MARK: - PiholeVersion Tests
    
    @Test("PiholeVersion has correct raw values")
    func testPiholeVersionRawValues() {
        #expect(PiholeVersion.v5.rawValue == "v5")
        #expect(PiholeVersion.v6.rawValue == "v6")
    }
    
    @Test("PiholeVersion has correct user values")
    func testPiholeVersionUserValues() {
        #expect(PiholeVersion.v5.userValue == "Version 5.x")
        #expect(PiholeVersion.v6.userValue == "Version 6.x")
    }
    
    @Test("PiholeVersion conforms to Identifiable")
    func testPiholeVersionIdentifiable() {
        #expect(PiholeVersion.v5.id == "v5")
        #expect(PiholeVersion.v6.id == "v6")
    }
    
    // MARK: - PiholeSummary Tests
    
    @Test("PiholeSummary initializes correctly")
    func testPiholeSummaryInitialization() {
        let summary = PiholeSummary(
            domainsBeingBlocked: 150000,
            queries: 5000,
            adsBlocked: 1000,
            adsPercentageToday: 20.0,
            uniqueDomains: 500,
            queriesForwarded: 3000
        )
        
        #expect(summary.domainsBeingBlocked == 150000)
        #expect(summary.queries == 5000)
        #expect(summary.adsBlocked == 1000)
        #expect(summary.adsPercentageToday == 20.0)
        #expect(summary.uniqueDomains == 500)
        #expect(summary.queriesForwarded == 3000)
    }
    
    @Test("PiholeSummary is Codable")
    func testPiholeSummaryCodable() throws {
        let summary = PiholeSummary(
            domainsBeingBlocked: 150000,
            queries: 5000,
            adsBlocked: 1000,
            adsPercentageToday: 20.0,
            uniqueDomains: 500,
            queriesForwarded: 3000
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(summary)
        
        let decoder = JSONDecoder()
        let decodedSummary = try decoder.decode(PiholeSummary.self, from: data)
        
        #expect(decodedSummary.domainsBeingBlocked == summary.domainsBeingBlocked)
        #expect(decodedSummary.queries == summary.queries)
        #expect(decodedSummary.adsBlocked == summary.adsBlocked)
        #expect(decodedSummary.adsPercentageToday == summary.adsPercentageToday)
    }
    
    // MARK: - PiholeStatus Tests
    
    @Test("PiholeStatus has correct raw values")
    func testPiholeStatusRawValues() {
        #expect(PiholeStatus.enabled.rawValue == "enabled")
        #expect(PiholeStatus.disabled.rawValue == "disabled")
        #expect(PiholeStatus.unknown.rawValue == "unknown")
    }
    
    @Test("PiholeStatus is Codable")
    func testPiholeStatusCodable() throws {
        let enabled = PiholeStatus.enabled
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(enabled)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PiholeStatus.self, from: data)
        
        #expect(decoded == .enabled)
    }
    
    // MARK: - HistoryItem Tests
    
    @Test("HistoryItem initializes correctly")
    func testHistoryItemInitialization() {
        let date = Date()
        let item = HistoryItem(timestamp: date, blocked: 100, forwarded: 200)
        
        #expect(item.timestamp == date)
        #expect(item.blocked == 100)
        #expect(item.forwarded == 200)
    }
    
    @Test("HistoryItem is Identifiable")
    func testHistoryItemIdentifiable() {
        let item1 = HistoryItem(timestamp: Date(), blocked: 100, forwarded: 200)
        let item2 = HistoryItem(timestamp: Date(), blocked: 100, forwarded: 200)
        
        #expect(item1.id != item2.id)
    }
    
    // MARK: - PiMonitorMetrics Tests
    
    @Test("PiMonitorMetrics initializes correctly")
    func testPiMonitorMetricsInitialization() {
        let memory = PiMonitorMetrics.Memory(
            totalMemory: 4096000,
            freeMemory: 2048000,
            availableMemory: 3072000
        )
        
        let metrics = PiMonitorMetrics(
            socTemperature: 45.5,
            uptime: 86400.0,
            loadAverage: [0.5, 0.6, 0.7],
            kernelRelease: "5.10.0-rpi1",
            memory: memory
        )
        
        #expect(metrics.socTemperature == 45.5)
        #expect(metrics.uptime == 86400.0)
        #expect(metrics.loadAverage == [0.5, 0.6, 0.7])
        #expect(metrics.kernelRelease == "5.10.0-rpi1")
        #expect(metrics.memory.totalMemory == 4096000)
        #expect(metrics.memory.freeMemory == 2048000)
        #expect(metrics.memory.availableMemory == 3072000)
    }
    
    @Test("PiMonitorMetrics is Codable")
    func testPiMonitorMetricsCodable() throws {
        let memory = PiMonitorMetrics.Memory(
            totalMemory: 4096000,
            freeMemory: 2048000,
            availableMemory: 3072000
        )
        
        let metrics = PiMonitorMetrics(
            socTemperature: 45.5,
            uptime: 86400.0,
            loadAverage: [0.5, 0.6, 0.7],
            kernelRelease: "5.10.0-rpi1",
            memory: memory
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(metrics)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let decoded = try decoder.decode(PiMonitorMetrics.self, from: data)
        
        #expect(decoded.socTemperature == metrics.socTemperature)
        #expect(decoded.uptime == metrics.uptime)
        #expect(decoded.kernelRelease == metrics.kernelRelease)
    }
    
    // MARK: - PiMonitorEnvironment Tests
    
    @Test("PiMonitorEnvironment initializes correctly")
    func testPiMonitorEnvironmentInitialization() {
        let env = PiMonitorEnvironment(host: "192.168.1.100", port: 8088, secure: true)
        
        #expect(env.host == "192.168.1.100")
        #expect(env.port == 8088)
        #expect(env.secure == true)
    }
    
    @Test("PiMonitorEnvironment uses default values")
    func testPiMonitorEnvironmentDefaults() {
        let env = PiMonitorEnvironment(host: "192.168.1.100")
        
        #expect(env.host == "192.168.1.100")
        #expect(env.port == 8088)
        #expect(env.secure == false)
    }
    
    @Test("PiMonitorEnvironment is Hashable")
    func testPiMonitorEnvironmentHashable() {
        let env1 = PiMonitorEnvironment(host: "192.168.1.100", port: 8088, secure: false)
        let env2 = PiMonitorEnvironment(host: "192.168.1.100", port: 8088, secure: false)
        let env3 = PiMonitorEnvironment(host: "192.168.1.101", port: 8088, secure: false)
        
        #expect(env1 == env2)
        #expect(env1 != env3)
    }
    
    // MARK: - PiMonitorError Tests
    
    @Test("PiMonitorError enum cases exist")
    func testPiMonitorErrorCases() {
        let error1: PiMonitorError = .malformedURL
        let _: PiMonitorError = .sessionError(TestHelpers.createNetworkError())
        let error3: PiMonitorError = .invalidResponseCode(404)
        let _: PiMonitorError = .invalidResponse
        let _: PiMonitorError = .invalidDecode(TestHelpers.createNetworkError())
        
        switch error1 {
        case .malformedURL:
            break // Expected
        default:
            Issue.record("Wrong error case")
        }
        
        switch error3 {
        case .invalidResponseCode(let code):
            #expect(code == 404)
        default:
            Issue.record("Wrong error case")
        }
    }
    
    // MARK: - PiholeServiceError Tests
    
    @Test("PiholeServiceError enum cases exist")
    func testPiholeServiceErrorCases() {
        let error1: PiholeServiceError = .missingToken
        let _: PiholeServiceError = .invalidAuthenticationResponse
        let _: PiholeServiceError = .badURL
        let _: PiholeServiceError = .cannotParseResponse
        let _: PiholeServiceError = .unknownStatus
        let _: PiholeServiceError = .networkError(TestHelpers.createNetworkError())
        let _: PiholeServiceError = .encodingError(TestHelpers.createNetworkError())
        let _: PiholeServiceError = .unknownError
        let _: PiholeServiceError = .piMonitorNotSet
        let _: PiholeServiceError = .piMonitorError(.malformedURL)
        let error11: PiholeServiceError = .apiSeatsExceeded
        
        switch error1 {
        case .missingToken:
            break // Expected
        default:
            Issue.record("Wrong error case")
        }
        
        switch error11 {
        case .apiSeatsExceeded:
            break // Expected
        default:
            Issue.record("Wrong error case")
        }
    }
}

