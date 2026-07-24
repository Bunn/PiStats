//
//  PiStatsMini_Watch_AppTests.swift
//  PiStatsMini Watch AppTests
//
//  Created by Fernando Bunn on 24/07/2026.
//

import PiStatsCore
import Testing
@testable import PiStatsMini_Watch_App

struct PiStatsMini_Watch_AppTests {

    @MainActor
    @Test
    func firstRunExplainsHowToFetchSettingsFromTheIPhone() {
        let dashboard = WatchDashboardModel(piholes: [])

        #expect(
            dashboard.emptyStateMessage
                == "Open Pi Stats on your iPhone to fetch your Pi-hole settings."
        )
    }

    @Test
    func payloadRoundTripPreservesCredentialsAndMultipleConfigurations() throws {
        let first = Pihole(
            name: "Home",
            address: "pi.hole",
            password: "home-password"
        )
        let second = Pihole(
            name: "Lab",
            address: "10.0.0.2",
            port: 8080,
            secure: true,
            password: "lab-password"
        )

        let encoded = try PiholeWatchPayload(piholes: [first, second]).encoded()
        let decoded = try PiholeWatchPayload.decode(encoded).piholes

        #expect(decoded == [first, second])
    }

    @MainActor
    @Test
    func modelRefreshesMetricsAndControlsOnlyItsOwnPihole() async {
        let pihole = Pihole(name: "Home", address: "pi.hole")
        let service = ScriptedService(pihole: pihole)
        let model = WatchPiholeModel(pihole: pihole, service: service)

        await model.refresh()

        #expect(model.summary?.queries == 12_345)
        #expect(model.summary?.adsBlocked == 678)
        #expect(model.status == .enabled)

        await model.disable(timer: 300)
        #expect(model.status == .disabled)
        #expect(await service.lastDisableTimer == 300)

        await model.enable()
        #expect(model.status == .enabled)
    }

    @MainActor
    @Test
    func dashboardPausesAndResumesEveryConnectedPihole() async {
        let home = Pihole(name: "Home", address: "home.pi.hole")
        let lab = Pihole(name: "Lab", address: "lab.pi.hole")
        let homeService = ScriptedService(pihole: home)
        let labService = ScriptedService(pihole: lab)
        let homeModel = WatchPiholeModel(
            pihole: home,
            service: homeService
        )
        let labModel = WatchPiholeModel(
            pihole: lab,
            service: labService
        )
        let dashboard = WatchDashboardModel(
            piholes: [homeModel, labModel]
        )

        await dashboard.refreshAll()

        #expect(dashboard.connectedPiholeCount == 2)
        #expect(!dashboard.shouldResumeAll)

        await dashboard.pauseAll(timer: 30 * 60)

        #expect(homeModel.status == .disabled)
        #expect(labModel.status == .disabled)
        #expect(await homeService.lastDisableTimer == 30 * 60)
        #expect(await labService.lastDisableTimer == 30 * 60)
        #expect(dashboard.shouldResumeAll)

        await dashboard.resumeAll()

        #expect(homeModel.status == .enabled)
        #expect(labModel.status == .enabled)
        #expect(!dashboard.shouldResumeAll)
    }

    private actor ScriptedService: WatchPiholeServicing {
        nonisolated let pihole: Pihole
        private(set) var lastDisableTimer: Int?

        init(pihole: Pihole) {
            self.pihole = pihole
        }

        func fetchSummary() async throws -> PiholeSummary {
            PiholeSummary(
                domainsBeingBlocked: 200_000,
                queries: 12_345,
                adsBlocked: 678,
                adsPercentageToday: 5.49,
                uniqueDomains: 1_000,
                queriesForwarded: 9_000
            )
        }

        func fetchStatus() async throws -> PiholeStatus {
            .enabled
        }

        func enable() async throws -> PiholeStatus {
            .enabled
        }

        func disable(timer: Int?) async throws -> PiholeStatus {
            lastDisableTimer = timer
            return .disabled
        }
    }

}
