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
        systemMetricsEnabled: true,
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
    
    // MARK: - Test Piholes with HTTPS
    
    static let testPiholeV6HTTPS = Pihole(
        name: "Test Pi-hole V6 HTTPS",
        address: "pihole.example.com",
        version: .v6,
        port: 443,
        secure: true,
        token: "test-token-v6-https",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!
    )
    
    static let testPiholeV5HTTPS = Pihole(
        name: "Test Pi-hole V5 HTTPS",
        address: "pihole.example.com",
        version: .v5,
        port: 443,
        secure: true,
        token: "test-token-v5-https",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!
    )
    
    // MARK: - Test Piholes with Custom Ports
    
    static let testPiholeV6CustomPort = Pihole(
        name: "Test Pi-hole V6 Custom Port",
        address: "192.168.1.105",
        version: .v6,
        port: 8080,
        secure: false,
        token: "test-token-v6-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!
    )
    
    static let testPiholeV5CustomPort = Pihole(
        name: "Test Pi-hole V5 Custom Port",
        address: "192.168.1.106",
        version: .v5,
        port: 8080,
        secure: false,
        token: "test-token-v5-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!
    )
    
    static let testPiholeV6HTTPSCustomPort = Pihole(
        name: "Test Pi-hole V6 HTTPS Custom Port",
        address: "pihole.example.com",
        version: .v6,
        port: 8443,
        secure: true,
        token: "test-token-v6-https-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!
    )
    
    static let testPiholeV5HTTPSCustomPort = Pihole(
        name: "Test Pi-hole V5 HTTPS Custom Port",
        address: "pihole.example.com",
        version: .v5,
        port: 8443,
        secure: true,
        token: "test-token-v5-https-port",
        uuid: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!
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
    
    // MARK: - V5 Top Domains Mock Response

    nonisolated(unsafe) static let v5TopDomainsJSON: [String: Any] = [
        "top_queries": [
            "google.com": 500,
            "apple.com": 300,
            "github.com": 150
        ],
        "top_ads": [
            "ads.doubleclick.net": 1200,
            "tracker.facebook.com": 800,
            "analytics.google.com": 400
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

    // MARK: - V5 Top Clients Mock Response

    nonisolated(unsafe) static let v5TopClientsActiveJSON: [String: Any] = [
        "top_sources": [
            "MacBook-Pro|192.168.1.100": 5000,
            "iPhone|192.168.1.101": 3200,
            "192.168.1.150": 1500
        ]
    ]

    nonisolated(unsafe) static let v5TopClientsBlockedJSON: [String: Any] = [
        "top_sources_blocked": [
            "IoT-Camera|192.168.1.200": 2400,
            "Smart-TV|192.168.1.201": 1800,
            "Echo-Dot|192.168.1.202": 900
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

    nonisolated(unsafe) static let v5QueryTypesJSON: [String: Any] = [
        "querytypes": [
            "A (IPv4)": 60.0,
            "AAAA (IPv6)": 30.0,
            "HTTPS": 10.0,
            "PTR": 0.0
        ]
    ]

    nonisolated(unsafe) static let v6QueryTypesJSON: [String: Any] = [
        "types": [
            "A": 60,
            "AAAA": 30,
            "HTTPS": 10,
            "PTR": 0
        ]
    ]

    // MARK: - Upstreams Mock Responses

    nonisolated(unsafe) static let v5ForwardDestinationsJSON: [String: Any] = [
        "forward_destinations": [
            "8.8.8.8#53|dns.google": 70.0,
            "cache|cache": 20.0,
            "blocklist|blocklist": 10.0
        ]
    ]

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

    nonisolated(unsafe) static let v5AllQueriesJSON: [String: Any] = [
        "data": [
            ["1609459200", "A", "google.com", "192.168.1.10", "2"],
            ["1609459100", "AAAA", "ads.example.com", "192.168.1.11", "1"],
            ["1609459000", "A", "cdn.example.com", "192.168.1.12", "3"]
        ]
    ]

    nonisolated(unsafe) static let v6QueriesJSON: [String: Any] = [
        "queries": [
            ["time": 1609459200.0, "type": "A", "domain": "google.com", "client": ["ip": "192.168.1.10", "name": "laptop"], "status": "FORWARDED"],
            ["time": 1609459100.0, "type": "AAAA", "domain": "ads.example.com", "client": ["ip": "192.168.1.11", "name": ""], "status": "GRAVITY"],
            ["time": 1609459000.0, "type": "A", "domain": "cdn.example.com", "client": ["ip": "192.168.1.12"], "status": "CACHE"]
        ]
    ]

    // MARK: - Health Mock Responses

    nonisolated(unsafe) static let v5VersionsJSON: [String: Any] = [
        "core_update": false,
        "web_update": true,
        "FTL_update": false,
        "core_current": "v5.18",
        "web_current": "v5.21",
        "FTL_current": "v5.25"
    ]

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
