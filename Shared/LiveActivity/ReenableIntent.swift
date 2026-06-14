//
//  ReenableIntent.swift
//  PiStats
//
//  Re-enables blocking on all Pi-holes and dismisses the "blocking paused" Live
//  Activity.
//
//  IMPORTANT: this intent is compiled into BOTH the app and the widget extension.
//  ActivityKit's `Activity.activities` is process-scoped, and the activity is
//  started by the app — so it can only be ended from the app's process. When a
//  LiveActivityIntent exists in both targets the system runs it in the app, which
//  is exactly what we need for `DisableActivityController().end()` to find it.
//  (If this lived only in the widget extension it would run there and see zero
//  activities, leaving the Live Activity stuck on screen.)
//

import AppIntents
import Foundation
import WidgetKit
import PiStatsCore

struct ReenableIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Re-enable Pi-hole"
    static var description = IntentDescription("Turn Pi-hole blocking back on")

    init() {}

    func perform() async throws -> some IntentResult {
        let piholes = piholeStorage.restoreAllPiholes()
        // Re-enable, but always dismiss the activity afterwards even if the
        // network call fails — the disable was timed, so blocking resumes on its
        // own anyway, and the paused activity must not linger after a tap.
        do {
            try await PiholeActionService().enableAll(piholes)
        } catch {
            Log.widget.error("ReenableIntent enableAll failed: \(String(describing: error), privacy: .public)")
        }
        await DisableActivityController().end()
        // Reflect the new (enabled) status everywhere the user might be looking.
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadControls(ofKind: "dev.bunn.PiStatsMobile.PiholeToggle")
        return .result()
    }
}
