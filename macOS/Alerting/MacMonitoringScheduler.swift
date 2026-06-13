//
//  MacMonitoringScheduler.swift
//  Pi Stats (macOS)
//
//  Samples the already-running poll state on a fixed cadence and feeds snapshots
//  to the AlertEngine. Tied to the menu-bar polling lifecycle; it does NOT touch
//  the data updaters' start/stop.
//

import Foundation
import PiStatsCore

@MainActor
final class MacMonitoringScheduler {
    private let engine: AlertEngine
    private let interval: TimeInterval
    private let snapshotProvider: () -> [PiholeSnapshot]
    private var timer: Timer?

    init(engine: AlertEngine,
         interval: TimeInterval = 60,
         snapshotProvider: @escaping () -> [PiholeSnapshot]) {
        self.engine = engine
        self.interval = interval
        self.snapshotProvider = snapshotProvider
    }

    func start() {
        stop()
        Task { await requestAuthorizationIfEnabled() }
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func sample() {
        let snapshots = snapshotProvider()
        let settings = AlertSettingsStore.load()
        Task {
            await engine.update(settings: settings)
            for snapshot in snapshots {
                await engine.ingest(snapshot)
            }
        }
    }

    private func requestAuthorizationIfEnabled() async {
        guard AlertSettingsStore.load().masterEnabled else { return }
        _ = await LocalNotificationDispatcher().requestAuthorizationIfNeeded()
    }
}
