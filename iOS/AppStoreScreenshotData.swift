#if DEBUG
import Foundation
import PiStatsCore

@MainActor
enum AppStoreScreenshotData {
    private static let launchArgument = "--app-store-screenshots"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func configure(_ settingsStore: SettingsStore) {
        settingsStore.settingsViewModel.displayStatsAsList = false
        settingsStore.settingsViewModel.displayAllPiholes = true
        settingsStore.settingsViewModel.disablePermanently = false
        settingsStore.settingsViewModel.temperatureScale = .celsius
    }

    static func makeListUpdater() -> PiholeListUpdater {
        let home = Pihole(
            name: "Home Network",
            address: "home.pi",
            version: .v6,
            systemMetricsEnabled: true
        )
        let studio = Pihole(
            name: "Studio Pi-hole",
            address: "studio.pi",
            version: .v6,
            systemMetricsEnabled: true
        )

        let listUpdater = PiholeListUpdater([home, studio])
        applyHomeData(to: listUpdater.dataUpdaters[0].summary)
        applyStudioData(to: listUpdater.dataUpdaters[1].summary)
        return listUpdater
    }

    private static func applyHomeData(to summary: PiholeSummaryData) {
        summary.name = "Home Network"
        summary.totalQueries = "182,436"
        summary.queriesBlocked = "34,982"
        summary.percentageBlocked = "19.17%"
        summary.domainsOnList = "1,257,842"
        summary.status = .enabled
        summary.connectionState = .connected
        summary.hasLoadedSummary = true
        summary.hasLoadedStatus = true
        summary.history = history(multiplier: 1.0, phase: 0)
        summary.queryTypes = QueryTypesResult(types: [
            QueryTypeItem(name: "A (IPv4)", percentage: 48.7),
            QueryTypeItem(name: "AAAA (IPv6)", percentage: 24.5),
            QueryTypeItem(name: "HTTPS", percentage: 15.8),
            QueryTypeItem(name: "PTR", percentage: 6.2),
            QueryTypeItem(name: "SRV", percentage: 2.9),
            QueryTypeItem(name: "Other", percentage: 1.9),
        ])
        summary.upstreams = UpstreamsResult(upstreams: [
            UpstreamItem(name: "Cloudflare", ip: "1.1.1.1", percentage: 46.8),
            UpstreamItem(name: "Cloudflare", ip: "1.0.0.1", percentage: 32.1),
            UpstreamItem(name: "Local cache", ip: "cache", percentage: 15.4),
            UpstreamItem(name: "Other", ip: "", percentage: 5.7),
        ])
        summary.topDomains = TopDomainsResult(
            topPermitted: [
                TopDomainItem(domain: "github.com", count: 4_826),
                TopDomainItem(domain: "developer.apple.com", count: 3_942),
                TopDomainItem(domain: "icloud.com", count: 3_518),
                TopDomainItem(domain: "home-assistant.io", count: 2_764),
                TopDomainItem(domain: "cloudflare.com", count: 2_185),
            ],
            topBlocked: [
                TopDomainItem(domain: "telemetry.example", count: 2_946),
                TopDomainItem(domain: "ads.example", count: 2_417),
                TopDomainItem(domain: "tracking.example", count: 1_982),
                TopDomainItem(domain: "metrics.example", count: 1_327),
                TopDomainItem(domain: "sponsor.example", count: 968),
            ]
        )
        summary.topClients = TopClientsResult(
            topActive: [
                TopClientItem(ip: "192.168.1.42", name: "MacBook Pro", count: 28_164),
                TopClientItem(ip: "192.168.1.18", name: "Living Room TV", count: 21_809),
                TopClientItem(ip: "192.168.1.31", name: "iPhone", count: 18_456),
                TopClientItem(ip: "192.168.1.10", name: "Home Assistant", count: 14_923),
            ],
            topBlocked: [
                TopClientItem(ip: "192.168.1.18", name: "Living Room TV", count: 8_204),
                TopClientItem(ip: "192.168.1.42", name: "MacBook Pro", count: 6_481),
                TopClientItem(ip: "192.168.1.31", name: "iPhone", count: 4_956),
                TopClientItem(ip: "192.168.1.24", name: "Game Console", count: 3_708),
            ]
        )
        summary.health = PiholeHealth(
            coreVersion: "v6.1.4",
            webVersion: "v6.2.1",
            ftlVersion: "v6.3.2",
            updateAvailable: false,
            messages: []
        )
        summary.systemMetrics = PiMonitorMetrics(
            socTemperature: 46.8,
            uptime: 889_740,
            loadAverage: [0.16, 0.21, 0.18],
            kernelRelease: "6.12.34+rpt-rpi-v8",
            memory: PiMonitorMetrics.Memory(
                totalMemory: 8_192_000,
                freeMemory: 2_424_000,
                availableMemory: 5_160_000,
                usedMemory: 3_032_000,
                percentageUsed: 37
            )
        )
    }

    private static func applyStudioData(to summary: PiholeSummaryData) {
        summary.name = "Studio Pi-hole"
        summary.totalQueries = "96,284"
        summary.queriesBlocked = "12,041"
        summary.percentageBlocked = "12.51%"
        summary.domainsOnList = "1,257,842"
        summary.status = .enabled
        summary.connectionState = .connected
        summary.hasLoadedSummary = true
        summary.hasLoadedStatus = true
        summary.history = history(multiplier: 0.68, phase: 17)
        summary.queryTypes = QueryTypesResult(types: [
            QueryTypeItem(name: "A (IPv4)", percentage: 52.1),
            QueryTypeItem(name: "AAAA (IPv6)", percentage: 21.9),
            QueryTypeItem(name: "HTTPS", percentage: 14.6),
            QueryTypeItem(name: "PTR", percentage: 7.8),
            QueryTypeItem(name: "Other", percentage: 3.6),
        ])
        summary.upstreams = UpstreamsResult(upstreams: [
            UpstreamItem(name: "Quad9", ip: "9.9.9.9", percentage: 55.2),
            UpstreamItem(name: "Quad9", ip: "149.112.112.112", percentage: 31.7),
            UpstreamItem(name: "Local cache", ip: "cache", percentage: 13.1),
        ])
        summary.topDomains = TopDomainsResult(
            topPermitted: [
                TopDomainItem(domain: "apple.com", count: 2_842),
                TopDomainItem(domain: "github.com", count: 2_316),
                TopDomainItem(domain: "figma.com", count: 1_978),
                TopDomainItem(domain: "cloudflare.com", count: 1_624),
            ],
            topBlocked: [
                TopDomainItem(domain: "analytics.example", count: 1_486),
                TopDomainItem(domain: "ads.example", count: 1_137),
                TopDomainItem(domain: "tracking.example", count: 842),
                TopDomainItem(domain: "metrics.example", count: 619),
            ]
        )
        summary.topClients = TopClientsResult(
            topActive: [
                TopClientItem(ip: "10.0.0.21", name: "Studio Mac", count: 19_842),
                TopClientItem(ip: "10.0.0.37", name: "iPad Pro", count: 12_417),
                TopClientItem(ip: "10.0.0.15", name: "NAS", count: 9_682),
            ],
            topBlocked: [
                TopClientItem(ip: "10.0.0.21", name: "Studio Mac", count: 4_176),
                TopClientItem(ip: "10.0.0.37", name: "iPad Pro", count: 3_194),
                TopClientItem(ip: "10.0.0.44", name: "Smart Display", count: 2_087),
            ]
        )
        summary.health = PiholeHealth(
            coreVersion: "v6.1.4",
            webVersion: "v6.2.1",
            ftlVersion: "v6.3.2",
            updateAvailable: false,
            messages: []
        )
        summary.systemMetrics = PiMonitorMetrics(
            socTemperature: 43.2,
            uptime: 1_416_180,
            loadAverage: [0.08, 0.12, 0.10],
            kernelRelease: "6.12.34+rpt-rpi-v8",
            memory: PiMonitorMetrics.Memory(
                totalMemory: 4_096_000,
                freeMemory: 1_312_000,
                availableMemory: 2_826_000,
                usedMemory: 1_270_000,
                percentageUsed: 31
            )
        )
    }

    private static func history(multiplier: Double, phase: Int) -> [HistoryItem] {
        let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)
        return (0..<144).map { index in
            let wave = (sin(Double(index + phase) / 11) + 1) * 48
            let activity = (cos(Double(index + phase) / 23) + 1) * 18
            let forwarded = Int((42 + wave + activity) * multiplier)
            let blocked = Int(Double(forwarded) * (0.14 + Double(index % 9) / 100))
            return HistoryItem(
                timestamp: referenceDate.addingTimeInterval(Double(index - 143) * 600),
                blocked: blocked,
                forwarded: forwarded
            )
        }
    }
}
#endif
