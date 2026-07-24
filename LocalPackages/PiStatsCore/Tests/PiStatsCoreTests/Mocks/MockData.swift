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
    
    static let testPiholeV6 = Pihole(
        name: "Test Pi-hole V6",
        address: "192.168.1.101",
        port: 80,
        password: "test-password-v6",
        systemMetricsEnabled: true,
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    )
    
    static let testPiholeV6NoPassword = Pihole(
        name: "Test Pi-hole V6 No Password",
        address: "192.168.1.103",
        port: 80,
        password: nil,
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!
    )
    
    // MARK: - Test Piholes with HTTPS
    
    static let testPiholeV6HTTPS = Pihole(
        name: "Test Pi-hole V6 HTTPS",
        address: "pihole.example.com",
        port: 443,
        secure: true,
        password: "test-password-v6-https",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    )
    
    // MARK: - Test Piholes with Custom Ports
    
    static let testPiholeV6CustomPort = Pihole(
        name: "Test Pi-hole V6 Custom Port",
        address: "192.168.1.105",
        port: 8080,
        secure: false,
        password: "test-password-v6-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    )
    
    static let testPiholeV6HTTPSCustomPort = Pihole(
        name: "Test Pi-hole V6 HTTPS Custom Port",
        address: "pihole.example.com",
        port: 8443,
        secure: true,
        password: "test-password-v6-https-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!
    )
    
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
    
    // MARK: - V6 Top Domains Mock Responses

    nonisolated(unsafe) static let v6TopDomainsPermittedJSON: [String: Any] = [
        "domains": [
            ["domain": "google.com", "count": 500],
            ["domain": "apple.com", "count": 300],
            ["domain": "github.com", "count": 150]
        ]
    ]

    nonisolated(unsafe) static let v6TopDomainsBlockedJSON: [String: Any] = [
        "domains": [
            ["domain": "ads.doubleclick.net", "count": 1200],
            ["domain": "tracker.facebook.com", "count": 800],
            ["domain": "analytics.google.com", "count": 400]
        ]
    ]

    // MARK: - V6 Top Clients Mock Responses

    nonisolated(unsafe) static let v6TopClientsActiveJSON: [String: Any] = [
        "clients": [
            ["name": "MacBook-Pro", "ip": "192.168.1.100", "count": 5000],
            ["name": "iPhone", "ip": "192.168.1.101", "count": 3200],
            ["name": "", "ip": "192.168.1.150", "count": 1500]
        ]
    ]

    nonisolated(unsafe) static let v6TopClientsBlockedJSON: [String: Any] = [
        "clients": [
            ["name": "IoT-Camera", "ip": "192.168.1.200", "count": 2400],
            ["name": "Smart-TV", "ip": "192.168.1.201", "count": 1800],
            ["name": "Echo-Dot", "ip": "192.168.1.202", "count": 900]
        ]
    ]

    // MARK: - Query Types Mock Responses

    nonisolated(unsafe) static let v6QueryTypesJSON: [String: Any] = [
        "types": [
            "A": 60,
            "AAAA": 30,
            "HTTPS": 10,
            "PTR": 0
        ]
    ]

    // MARK: - Upstreams Mock Responses

    nonisolated(unsafe) static let v6UpstreamsJSON: [String: Any] = [
        "upstreams": [
            ["ip": "8.8.8.8", "name": "dns.google", "port": 53, "count": 60],
            ["ip": "1.1.1.1", "name": "", "port": 53, "count": 30],
            ["name": "cache", "port": -1, "count": 10]
        ],
        "forwarded_queries": 90,
        "total_queries": 100
    ]

    // MARK: - Query Log Mock Responses

    nonisolated(unsafe) static let v6QueriesJSON: [String: Any] = [
        "queries": [
            ["time": 1609459200.0, "type": "A", "domain": "google.com", "client": ["ip": "192.168.1.10", "name": "laptop"], "status": "FORWARDED"],
            ["time": 1609459100.0, "type": "AAAA", "domain": "ads.example.com", "client": ["ip": "192.168.1.11", "name": ""], "status": "GRAVITY"],
            ["time": 1609459000.0, "type": "A", "domain": "cdn.example.com", "client": ["ip": "192.168.1.12"], "status": "CACHE"]
        ]
    ]

    // MARK: - Health Mock Responses

    nonisolated(unsafe) static let v6VersionJSON: [String: Any] = [
        "version": [
            "core": ["local": ["version": "v6.0"], "remote": ["version": "v6.1"]],
            "web": ["local": ["version": "v6.1"], "remote": ["version": "v6.1"]],
            "ftl": ["local": ["version": "v6.1"], "remote": ["version": "v6.1"]]
        ]
    ]

    nonisolated(unsafe) static let v6MessagesJSON: [String: Any] = [
        "messages": [
            ["id": 1, "timestamp": 1609459200.0, "type": "SUBNET", "plain": "Rate-limiting 192.168.2.42", "html": "<code>192.168.2.42</code>"]
        ]
    ]

    nonisolated(unsafe) static let v6SystemMetricsJSON: [String: Any] = [
        "system": [
            "uptime": 86_400,
            "memory": [
                "ram": [
                    "total": 4_096_000,
                    "free": 2_048_000,
                    "available": 3_072_000,
                    "used": 1_024_000,
                    "%used": 25.0
                ]
            ],
            "cpu": [
                "load": [
                    "raw": [0.5, 0.6, 0.7],
                    "percent": [12.5, 15.0, 17.5]
                ]
            ]
        ]
    ]

    nonisolated(unsafe) static let v6SensorsJSON: [String: Any] = [
        "sensors": [
            "cpu_temp": 45.5,
            "hot_limit": 60.0,
            "unit": "C"
        ]
    ]

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
    
    static func expectedSystemMetrics() -> PiholeSystemMetrics {
        PiholeSystemMetrics(
            socTemperature: 45.5,
            uptime: 86400.0,
            loadAverage: [0.5, 0.6, 0.7],
            kernelRelease: "5.10.0-rpi1",
            memory: PiholeSystemMetrics.Memory(
                totalMemory: 4096000,
                freeMemory: 2048000,
                availableMemory: 3072000
            )
        )
    }
}
