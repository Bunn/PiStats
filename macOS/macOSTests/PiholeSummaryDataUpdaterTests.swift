import PiStatsCore
import Testing
@testable import Pi_Stats

@MainActor
struct PiholeSummaryDataUpdaterTests {
    private let pihole = Pihole(
        name: "Test",
        address: "192.0.2.1",
        password: "test"
    )

    @Test("Primary summary appears without waiting for status")
    func summaryAppearsIndependently() async throws {
        let service = ScriptedPiholeService(
            pihole: pihole,
            summaries: [.value(Self.summary)],
            statuses: [.value(.enabled, delay: .seconds(1))]
        )
        let updater = PiholeSummaryDataUpdater(pihole: pihole, service: service)

        let refresh = Task {
            await updater.refreshNow(includeSupplementaryData: false)
        }
        for _ in 0..<100 where !updater.summary.hasLoadedSummary {
            await Task.yield()
        }

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
            password: pihole.password,
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

    @Test("A current-only configuration change does not update other Pi-holes")
    func currentOnlyConfigurationChange() async throws {
        let setup = configurationSyncSetup()
        let rule = DomainRule(domain: "ads.example.com", type: .deny, kind: .exact)

        try await setup.listUpdater.addDomains(
            [rule],
            from: setup.currentUpdater,
            scope: .currentPihole
        )

        #expect(await setup.currentService.addDomainsRequestCount == 1)
        #expect(await setup.otherService.addDomainsRequestCount == 0)
    }

    @Test("Sync disabled asks for a scope when multiple Pi-holes are configured")
    func disabledConfigurationSyncAsksForScope() {
        let options = PiholeConfigurationSyncOptions(
            configuredPiholeCount: 2,
            automaticallySyncsChanges: false
        )

        #expect(options.requiresScopeConfirmation)
        #expect(options.automaticScope == .currentPihole)
    }

    @Test("Sync enabled automatically targets all configured Pi-holes")
    func enabledConfigurationSyncTargetsAllPiholes() {
        let options = PiholeConfigurationSyncOptions(
            configuredPiholeCount: 2,
            automaticallySyncsChanges: true
        )

        #expect(!options.requiresScopeConfirmation)
        #expect(options.automaticScope == .allPiholes)
    }

    @Test("An all-Pi-hole configuration change updates every Pi-hole")
    func allPiholesConfigurationChange() async throws {
        let setup = configurationSyncSetup()
        let rule = DomainRule(domain: "ads.example.com", type: .deny, kind: .exact)

        try await setup.listUpdater.addDomains(
            [rule],
            from: setup.currentUpdater,
            scope: .allPiholes
        )

        #expect(await setup.currentService.addDomainsRequestCount == 1)
        #expect(await setup.otherService.addDomainsRequestCount == 1)
    }

    @Test("A failed secondary sync reports a partial failure without undoing the current Pi-hole")
    func secondaryConfigurationSyncFailure() async throws {
        let setup = configurationSyncSetup(otherMutationShouldFail: true)
        let rule = DomainRule(domain: "ads.example.com", type: .deny, kind: .exact)

        do {
            try await setup.listUpdater.addDomains(
                [rule],
                from: setup.currentUpdater,
                scope: .allPiholes
            )
            Issue.record("Expected the secondary Pi-hole mutation to fail")
        } catch let error as PiholeConfigurationSyncError {
            #expect(error.currentPiholeWasUpdated)
            #expect(error.failures.count == 1)
            #expect(error.failures.first?.piholeName == setup.otherUpdater.pihole.name)
        }

        #expect(await setup.currentService.addDomainsRequestCount == 1)
        #expect(await setup.otherService.addDomainsRequestCount == 1)
    }

    @Test("A failed current mutation stops before updating other Pi-holes")
    func currentConfigurationSyncFailure() async throws {
        let setup = configurationSyncSetup(currentMutationShouldFail: true)
        let rule = DomainRule(domain: "ads.example.com", type: .deny, kind: .exact)

        do {
            try await setup.listUpdater.addDomains(
                [rule],
                from: setup.currentUpdater,
                scope: .allPiholes
            )
            Issue.record("Expected the current Pi-hole mutation to fail")
        } catch {
            #expect(error is PiholeConfigurationSyncError == false)
        }

        #expect(await setup.currentService.addDomainsRequestCount == 1)
        #expect(await setup.otherService.addDomainsRequestCount == 0)
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

    private func configurationSyncSetup(
        currentMutationShouldFail: Bool = false,
        otherMutationShouldFail: Bool = false
    ) -> (
        listUpdater: PiholeListUpdater,
        currentUpdater: PiholeSummaryDataUpdater,
        otherUpdater: PiholeSummaryDataUpdater,
        currentService: ScriptedPiholeService,
        otherService: ScriptedPiholeService
    ) {
        let currentPihole = Pihole(
            name: "Primary",
            address: "192.0.2.10",
            password: "test"
        )
        let otherPihole = Pihole(
            name: "Secondary",
            address: "192.0.2.11",
            password: "test"
        )
        let currentService = ScriptedPiholeService(
            pihole: currentPihole,
            summaries: [],
            statuses: [],
            mutationShouldFail: currentMutationShouldFail
        )
        let otherService = ScriptedPiholeService(
            pihole: otherPihole,
            summaries: [],
            statuses: [],
            mutationShouldFail: otherMutationShouldFail
        )
        let currentUpdater = PiholeSummaryDataUpdater(
            pihole: currentPihole,
            service: currentService
        )
        let otherUpdater = PiholeSummaryDataUpdater(
            pihole: otherPihole,
            service: otherService
        )

        return (
            PiholeListUpdater(dataUpdaters: [currentUpdater, otherUpdater]),
            currentUpdater,
            otherUpdater,
            currentService,
            otherService
        )
    }
}
