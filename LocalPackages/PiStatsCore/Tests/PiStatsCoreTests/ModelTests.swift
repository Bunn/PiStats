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
        
        let pihole = Pihole(
            name: "Test Pi-hole",
            address: "192.168.1.100",
            port: 80,
            password: "test-password",
            systemMetricsEnabled: true,
            uuid: uuid
        )
        
        #expect(pihole.name == "Test Pi-hole")
        #expect(pihole.address == "192.168.1.100")
        #expect(pihole.port == 80)
        #expect(pihole.password == "test-password")
        #expect(pihole.systemMetricsEnabled)
        #expect(pihole.uuid == uuid)
        #expect(pihole.id == uuid)
    }
    
    @Test("Pihole uses default values")
    func testPiholeDefaults() {
        let pihole = Pihole(name: "Test", address: "192.168.1.100")

        #expect(pihole.port == 80)
        #expect(pihole.password == nil)
        #expect(pihole.systemMetricsEnabled == false)
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

    // MARK: - UpstreamItem Tests

    @Test("Upstream identity is stable and distinguishes same-name endpoints")
    func testUpstreamIdentity() {
        let primary = UpstreamItem(
            name: "one.one.one.one",
            ip: "1.1.1.1",
            port: 53,
            percentage: 60
        )
        let refreshed = UpstreamItem(
            name: "one.one.one.one",
            ip: "1.1.1.1",
            port: 53,
            percentage: 55
        )
        let secondary = UpstreamItem(
            name: "one.one.one.one",
            ip: "1.0.0.1",
            port: 53,
            percentage: 35
        )
        let alternatePort = UpstreamItem(
            name: "one.one.one.one",
            ip: "1.1.1.1",
            port: 5353,
            percentage: 10
        )

        #expect(primary.id == refreshed.id)
        #expect(primary.id != secondary.id)
        #expect(primary.id != alternatePort.id)
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
    
    // MARK: - PiholeSystemMetrics Tests
    
    @Test("PiholeSystemMetrics initializes correctly")
    func testPiholeSystemMetricsInitialization() {
        let memory = PiholeSystemMetrics.Memory(
            totalMemory: 4096000,
            freeMemory: 2048000,
            availableMemory: 3072000
        )
        
        let metrics = PiholeSystemMetrics(
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
        #expect(metrics.memory.usedFraction == 0.25)
    }
    
    @Test("PiholeSystemMetrics is Codable")
    func testPiholeSystemMetricsCodable() throws {
        let memory = PiholeSystemMetrics.Memory(
            totalMemory: 4096000,
            freeMemory: 2048000,
            availableMemory: 3072000
        )
        
        let metrics = PiholeSystemMetrics(
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
        let decoded = try decoder.decode(PiholeSystemMetrics.self, from: data)
        
        #expect(decoded.socTemperature == metrics.socTemperature)
        #expect(decoded.uptime == metrics.uptime)
        #expect(decoded.kernelRelease == metrics.kernelRelease)
    }
    
    // MARK: - TopDomainsResult Tests

    @Test("TopDomainsResult initializes correctly")
    func testTopDomainsResultInitialization() {
        let permitted = [TopDomainItem(domain: "google.com", count: 500)]
        let blocked = [TopDomainItem(domain: "ads.example.com", count: 200)]

        let result = TopDomainsResult(topPermitted: permitted, topBlocked: blocked)

        #expect(result.topPermitted.count == 1)
        #expect(result.topBlocked.count == 1)
        #expect(result.topPermitted[0].domain == "google.com")
        #expect(result.topBlocked[0].domain == "ads.example.com")
    }

    @Test("TopDomainsResult handles empty arrays")
    func testTopDomainsResultEmpty() {
        let result = TopDomainsResult(topPermitted: [], topBlocked: [])

        #expect(result.topPermitted.isEmpty)
        #expect(result.topBlocked.isEmpty)
    }

    // MARK: - TopDomainItem Tests

    @Test("TopDomainItem initializes correctly")
    func testTopDomainItemInitialization() {
        let item = TopDomainItem(domain: "example.com", count: 42)

        #expect(item.domain == "example.com")
        #expect(item.count == 42)
    }

    @Test("TopDomainItem has unique Identifiable IDs")
    func testTopDomainItemIdentifiable() {
        let item1 = TopDomainItem(domain: "example.com", count: 42)
        let item2 = TopDomainItem(domain: "example.com", count: 42)

        #expect(item1.id != item2.id)
    }

    // MARK: - TopClientsResult Tests

    @Test("TopClientsResult initializes correctly")
    func testTopClientsResultInitialization() {
        let active = [
            TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000),
            TopClientItem(ip: "192.168.1.101", name: "iPhone", count: 3200)
        ]
        let blocked = [
            TopClientItem(ip: "192.168.1.200", name: "IoT-Camera", count: 2400)
        ]

        let result = TopClientsResult(topActive: active, topBlocked: blocked)

        #expect(result.topActive.count == 2)
        #expect(result.topBlocked.count == 1)
        #expect(result.topActive[0].name == "MacBook-Pro")
        #expect(result.topBlocked[0].ip == "192.168.1.200")
    }

    @Test("TopClientsResult handles empty arrays")
    func testTopClientsResultEmpty() {
        let result = TopClientsResult(topActive: [], topBlocked: [])

        #expect(result.topActive.isEmpty)
        #expect(result.topBlocked.isEmpty)
    }

    // MARK: - TopClientItem Tests

    @Test("TopClientItem initializes correctly")
    func testTopClientItemInitialization() {
        let item = TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000)

        #expect(item.ip == "192.168.1.100")
        #expect(item.name == "MacBook-Pro")
        #expect(item.count == 5000)
    }

    @Test("TopClientItem has unique Identifiable IDs")
    func testTopClientItemIdentifiable() {
        let item1 = TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000)
        let item2 = TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000)

        #expect(item1.id != item2.id)
    }

    @Test("TopClientItem displayName returns name when available")
    func testTopClientItemDisplayNameWithName() {
        let item = TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000)

        #expect(item.displayName == "MacBook-Pro")
    }

    @Test("TopClientItem displayName returns IP when name is empty")
    func testTopClientItemDisplayNameWithoutName() {
        let item = TopClientItem(ip: "192.168.1.150", name: "", count: 1500)

        #expect(item.displayName == "192.168.1.150")
    }

    // MARK: - PiholeServiceError Tests
    
    @Test("PiholeServiceError enum cases exist")
    func testPiholeServiceErrorCases() {
        let error1: PiholeServiceError = .missingPassword
        let _: PiholeServiceError = .invalidAuthenticationResponse
        let _: PiholeServiceError = .badURL
        let _: PiholeServiceError = .cannotParseResponse
        let _: PiholeServiceError = .unknownStatus
        let _: PiholeServiceError = .networkError(TestHelpers.createNetworkError())
        let _: PiholeServiceError = .encodingError(TestHelpers.createNetworkError())
        let _: PiholeServiceError = .unknownError
        let seatsError: PiholeServiceError = .apiSeatsExceeded
        
        switch error1 {
        case .missingPassword:
            break // Expected
        default:
            Issue.record("Wrong error case")
        }
        
        switch seatsError {
        case .apiSeatsExceeded:
            break // Expected
        default:
            Issue.record("Wrong error case")
        }
    }
}
