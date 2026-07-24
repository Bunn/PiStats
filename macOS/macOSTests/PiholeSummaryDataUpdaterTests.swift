import PiStatsCore
import Testing
@testable import Pi_Stats

@MainActor
struct PiholeSummaryDataUpdaterTests {
    private let pihole = Pihole(
        name: "Test",
        address: "192.0.2.1",
        version: .v6,
        token: "test"
    )

    @Test("Primary summary appears without waiting for status")
    func summaryAppearsIndependently() async throws {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.value(Self.summary)],
            statuses: [.value(.enabled, delay: .milliseconds(250))]
        )
        let updater = PiholeSummaryDataUpdater(pihole: pihole, service: service)

        let refresh = Task {
            await updater.refreshNow(includeSupplementaryData: false)
        }
        try await Task.sleep(for: .milliseconds(50))

        #expect(updater.summary.hasLoadedSummary)
        #expect(updater.summary.totalQueries == "1,234")
        #expect(!updater.summary.hasLoadedStatus)
        #expect(!updater.summary.hasError)

        #expect(await refresh.value)
        #expect(updater.summary.status == .enabled)
        #expect(updater.summary.connectionState == .connected)
    }

    @Test("A transient cold-launch failure is hidden until it repeats")
    func transientColdLaunchFailureIsDebounced() async {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.networkFailure(), .networkFailure()],
            statuses: [.networkFailure(), .networkFailure()]
        )
        let updater = PiholeSummaryDataUpdater(pihole: pihole, service: service)

        #expect(await updater.refreshNow(includeSupplementaryData: false) == false)
        #expect(!updater.summary.hasError)
        #expect(updater.summary.connectionState == .connecting)

        #expect(await updater.refreshNow(includeSupplementaryData: false) == false)
        #expect(updater.summary.hasError)
        #expect(updater.summary.connectionState == .unavailable)
    }

    @Test("Failed refreshes preserve the last known good card")
    func failuresPreserveLastKnownGoodData() async {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.value(Self.summary), .networkFailure(), .networkFailure()],
            statuses: [.value(.enabled), .networkFailure(), .networkFailure()]
        )
        let updater = PiholeSummaryDataUpdater(pihole: pihole, service: service)

        #expect(await updater.refreshNow(includeSupplementaryData: false))
        #expect(await updater.refreshNow(includeSupplementaryData: false) == false)
        #expect(!updater.summary.hasError)
        #expect(updater.summary.connectionState == .stale)
        #expect(updater.summary.status == .enabled)
        #expect(updater.summary.totalQueries == "1,234")

        #expect(await updater.refreshNow(includeSupplementaryData: false) == false)
        #expect(updater.summary.hasError)
        #expect(updater.summary.connectionState == .unavailable)
        #expect(updater.summary.status == .enabled)
        #expect(updater.summary.totalQueries == "1,234")
    }

    @Test("One successful primary endpoint keeps the connection usable")
    func partialPrimarySuccessIsConnected() async {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.networkFailure()],
            statuses: [.value(.enabled)]
        )
        let updater = PiholeSummaryDataUpdater(pihole: pihole, service: service)

        #expect(await updater.refreshNow(includeSupplementaryData: false))
        #expect(updater.summary.connectionState == .connected)
        #expect(updater.summary.status == .enabled)
        #expect(!updater.summary.hasError)
        #expect(!updater.summary.hasLoadedSummary)
    }

    @Test("Saving one Pi-hole preserves its last known good card")
    func replacingPiholePreservesSummary() {
        let listUpdater = PiholeListUpdater([pihole])
        let original = listUpdater.dataUpdaters[0]
        original.summary.totalQueries = "9,876"
        original.summary.queriesBlocked = "432"
        original.summary.status = .enabled
        original.summary.hasLoadedSummary = true
        original.summary.hasLoadedStatus = true
        original.summary.connectionState = .connected

        let renamed = Pihole(
            name: "Renamed",
            address: pihole.address,
            version: pihole.version,
            token: pihole.token,
            uuid: pihole.uuid
        )
        listUpdater.updatePihole(renamed)

        let replacement = listUpdater.dataUpdaters[0]
        #expect(replacement !== original)
        #expect(replacement.summary.name == "Renamed")
        #expect(replacement.summary.totalQueries == "9,876")
        #expect(replacement.summary.queriesBlocked == "432")
        #expect(replacement.summary.status == .enabled)
        #expect(replacement.summary.connectionState == .stale)
    }

    @Test("Saving an unchanged Pi-hole keeps the existing connection")
    func savingUnchangedPiholeKeepsUpdater() {
        let listUpdater = PiholeListUpdater([pihole])
        let original = listUpdater.dataUpdaters[0]

        listUpdater.updatePihole(pihole)

        #expect(listUpdater.dataUpdaters[0] === original)
    }

    @Test("Starting twice does not duplicate the polling loop")
    func startUpdatingIsIdempotent() async throws {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.value(Self.summary)],
            statuses: [.value(.enabled)]
        )
        let updater = PiholeSummaryDataUpdater(
            pihole: pihole,
            service: service,
            primaryPollInterval: .seconds(60)
        )

        updater.startUpdating()
        updater.startUpdating()
        try await Task.sleep(for: .milliseconds(100))
        updater.stopUpdating()

        #expect(await service.summaryRequestCount == 1)
        #expect(await service.statusRequestCount == 1)
    }

    @Test("Restarting during an in-flight refresh keeps the new polling loop")
    func restartDuringRefreshKeepsNewPollingLoop() async throws {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [
                .value(Self.summary, delay: .seconds(2)),
                .value(Self.summary)
            ],
            statuses: [
                .value(.enabled, delay: .seconds(2)),
                .value(.enabled)
            ]
        )
        let updater = PiholeSummaryDataUpdater(
            pihole: pihole,
            service: service,
            primaryPollInterval: .seconds(60)
        )

        updater.startUpdating()
        for _ in 0..<100 {
            if await service.summaryRequestCount == 1,
               await service.statusRequestCount == 1 {
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(await service.summaryRequestCount == 1)
        #expect(await service.statusRequestCount == 1)

        updater.stopUpdating()
        updater.startUpdating()

        for _ in 0..<100 {
            if updater.summary.hasLoadedSummary, updater.summary.hasLoadedStatus {
                break
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        updater.stopUpdating()

        #expect(await service.summaryRequestCount == 2)
        #expect(await service.statusRequestCount == 2)
        #expect(updater.summary.totalQueries == "1,234")
        #expect(updater.summary.status == .enabled)
        #expect(updater.summary.connectionState == .connected)
    }

    private static let summary = PiholeSummary(
        domainsBeingBlocked: 98_765,
        queries: 1_234,
        adsBlocked: 321,
        adsPercentageToday: 26,
        uniqueDomains: 500,
        queriesForwarded: 800
    )
}
