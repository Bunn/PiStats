//
//  IOSMonitoringScheduler.swift
//  Pi Stats Mobile (iOS)
//
//  Best-effort background health checks via BGAppRefreshTask plus foreground
//  checks, feeding snapshots to the AlertEngine. iOS only fires the task when
//  the system schedules it and the Pi-hole is reachable from the device.
//

import Foundation
import BackgroundTasks
import PiStatsCore

@MainActor
final class IOSMonitoringScheduler {
    static let taskIdentifier = "dev.bunn.PiStatsMobile.healthcheck"

    private let engine: AlertEngine
    private let storage: PiholeStorage

    init(engine: AlertEngine, storage: PiholeStorage) {
        self.engine = engine
        self.storage = storage
    }

    /// Must be called before the app finishes launching (e.g. from App.init).
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            Task { await self.handle(refresh) }
        }
    }

    /// Asks iOS to run the health check again later.
    func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handle(_ task: BGAppRefreshTask) async {
        schedule() // chain the next run
        let work = Task { await runChecks() }
        task.expirationHandler = { work.cancel() }
        _ = await work.value
        task.setTaskCompleted(success: true)
    }

    /// Polls each Pi-hole once and ingests a snapshot. Safe to call from the
    /// foreground too.
    func runChecks() async {
        let settings = AlertSettingsStore.load()
        guard settings.masterEnabled else { return }
        await engine.update(settings: settings)

        for pihole in storage.restoreAllPiholes() {
            let client = PiholeAPIClient(pihole)
            do {
                let status = try await client.fetchStatus()
                let health = try? await client.fetchHealth()
                await engine.ingest(PiholeSnapshot(piholeID: pihole.uuid, piholeName: pihole.name,
                                                   reachable: true, status: status, health: health))
            } catch {
                await engine.ingest(PiholeSnapshot(piholeID: pihole.uuid, piholeName: pihole.name,
                                                   reachable: false, status: .unknown, health: nil))
            }
        }
    }
}
