//
//  QuickDisableIntent.swift
//  PiStats
//
//  Control Center "quick disable" action: pauses blocking on all Pi-holes for a
//  set time and starts the countdown Live Activity.
//
//  IMPORTANT: like ReenableIntent, this is compiled into BOTH the app and the
//  widget extension so the system runs it in the APP process. ActivityKit is
//  process-scoped, so the activity must be started (here) and later ended
//  (ReenableIntent) from the same process — the app. While this lived only in the
//  widget extension the control couldn't reliably surface the Live Activity and
//  the widget logged `unableToExtractStaticMetadata` for it.
//

import AppIntents
import Foundation
import WidgetKit
import PiStatsCore

struct QuickDisableIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Quick Disable Pi-hole"
    @Parameter(title: "Seconds") var seconds: Int

    init() {}
    init(seconds: Int) { self.seconds = seconds }

    func perform() async throws -> some IntentResult {
        Log.widget.notice("QuickDisableIntent.perform started")
        let piholes = piholeStorage.restoreAllPiholes()
        guard !piholes.isEmpty else { return .result() }
        try await PiholeActionService().disableAll(piholes, timer: seconds)
        Log.widget.notice("QuickDisableIntent disabled \(piholes.count, privacy: .public) pihole(s)")
        DisableActivityController().start(until: Date().addingTimeInterval(TimeInterval(seconds)))
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
