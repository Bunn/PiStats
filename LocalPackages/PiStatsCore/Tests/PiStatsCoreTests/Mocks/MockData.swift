//
//  MockData.swift
//  PiStatsCoreTests
//
//  Created for testing purposes
//

import Foundation
@testable import PiStatsCore

/// Mock data for testing
enum MockData {
    
    // MARK: - Test Piholes
    
    static let testPiholeV5 = Pihole(
        name: "Test Pi-hole V5",
        address: "192.168.1.100",
        version: .v5,
        port: 80,
        token: "test-token-v5",
        piMonitor: PiMonitorEnvironment(host: "192.168.1.100", port: 8088),
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    )
    
    static let testPiholeV6 = Pihole(
        name: "Test Pi-hole V6",
        address: "192.168.1.101",
        version: .v6,
        port: 80,
        token: "test-token-v6",
        piMonitor: PiMonitorEnvironment(host: "192.168.1.101", port: 8088),
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    )
    
    static let testPiholeV5NoToken = Pihole(
        name: "Test Pi-hole V5 No Token",
        address: "192.168.1.102",
        version: .v5,
        port: 80,
        token: nil,
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    )
    
    static let testPiholeV6NoToken = Pihole(
        name: "Test Pi-hole V6 No Token",
        address: "192.168.1.103",
        version: .v6,
        port: 80,
        token: nil,
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    )
    
    static let testPiholeV5NoPiMonitor = Pihole(
        name: "Test Pi-hole V5 No Monitor",
        address: "192.168.1.104",
        version: .v5,
        port: 80,
        token: "test-token-v5",
        piMonitor: nil,
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!
    )
    
    // MARK: - V5 Mock Responses
    
    nonisolated(unsafe) static let v5SummaryJSON: [String: Any] = [
        "domains_being_blocked": 150000,
        "dns_queries_today": 5000,
        "ads_blocked_today": 1000,
        "ads_percentage_today": 20.0,
        "unique_domains": 500,
        "queries_forwarded": 3000
    ]
    
    nonisolated(unsafe) static let v5StatusEnabledJSON: [String: Any] = [
        "status": "enabled"
    ]
    
    nonisolated(unsafe) static let v5StatusDisabledJSON: [String: Any] = [
        "status": "disabled"
    ]
    
    nonisolated(unsafe) static let v5HistoryJSON: [String: Any] = [
        "domains_over_time": [
            "1609459200": 100,
            "1609459800": 150,
            "1609460400": 200
        ],
        "ads_over_time": [
            "1609459200": 20,
            "1609459800": 30,
            "1609460400": 40
        ]
    ]
    
    // MARK: - V6 Mock Responses
    
    nonisolated(unsafe) static let v6AuthSuccessJSON: [String: Any] = [
        "session": [
            "sid": "test-session-id",
            "csrf": "test-csrf-token"
        ]
    ]
    
    nonisolated(unsafe) static let v6AuthFailureJSON: [String: Any] = [
        "error": [
            "key": "unauthorized",
            "message": "Invalid credentials"
        ]
    ]
    
    nonisolated(unsafe) static let v6AuthSeatsExceededJSON: [String: Any] = [
        "error": [
            "key": "api_seats_exceeded",
            "message": "Maximum number of API sessions exceeded"
        ]
    ]
    
    nonisolated(unsafe) static let v6SummaryJSON: [String: Any] = [
        "queries": [
            "total": 5000,
            "blocked": 1000,
            "percent_blocked": 20.0,
            "unique_domains": 500,
            "forwarded": 3000
        ],
        "gravity": [
            "domains_being_blocked": 150000
        ]
    ]
    
    nonisolated(unsafe) static let v6StatusEnabledJSON: [String: Any] = [
        "blocking": "enabled"
    ]
    
    nonisolated(unsafe) static let v6StatusDisabledJSON: [String: Any] = [
        "blocking": "disabled"
    ]
    
    nonisolated(unsafe) static let v6HistoryJSON: [String: Any] = [
        "history": [
            [
                "timestamp": 1609459200.0,
                "blocked": 20,
                "forwarded": 80,
                "cached": 20
            ],
            [
                "timestamp": 1609459800.0,
                "blocked": 30,
                "forwarded": 100,
                "cached": 20
            ],
            [
                "timestamp": 1609460400.0,
                "blocked": 40,
                "forwarded": 140,
                "cached": 20
            ]
        ]
    ]
    
    // MARK: - PiMonitor Mock Responses
    
    static let piMonitorMetricsJSON: Data = {
        let dict: [String: Any] = [
            "soc_temperature": 45.5,
            "uptime": 86400.0,
            "load_average": [0.5, 0.6, 0.7],
            "kernel_release": "5.10.0-rpi1",
            "memory": [
                "total_memory": 4096000,
                "free_memory": 2048000,
                "available_memory": 3072000
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: dict, options: [])
    }()
    
    // MARK: - Helper Methods
    
    static func jsonData(from dictionary: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
    
    static func expectedSummary() -> PiholeSummary {
        PiholeSummary(
            domainsBeingBlocked: 150000,
            queries: 5000,
            adsBlocked: 1000,
            adsPercentageToday: 20.0,
            uniqueDomains: 500,
            queriesForwarded: 3000
        )
    }
    
    static func expectedPiMonitorMetrics() -> PiMonitorMetrics {
        PiMonitorMetrics(
            socTemperature: 45.5,
            uptime: 86400.0,
            loadAverage: [0.5, 0.6, 0.7],
            kernelRelease: "5.10.0-rpi1",
            memory: PiMonitorMetrics.Memory(
                totalMemory: 4096000,
                freeMemory: 2048000,
                availableMemory: 3072000
            )
        )
    }
}

