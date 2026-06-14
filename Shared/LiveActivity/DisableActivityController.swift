//
//  DisableActivityController.swift
//  PiStats
//
//  Starts/ends the single "blocking paused" Live Activity. iOS only.
//

import ActivityKit
import Foundation
import PiStatsCore

struct DisableActivityController {

    func start(until: Date) {
        guard UserDefaults.isLiveActivityEnabled else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            Log.widget.error("Live Activities are disabled; cannot start countdown")
            return
        }
        let content = ActivityContent(state: PiholeDisableActivityAttributes.ContentState(endDate: until),
                                      staleDate: until)
        if let existing = Activity<PiholeDisableActivityAttributes>.activities.first {
            Task { await existing.update(content) }
            return
        }
        do {
            _ = try Activity.request(attributes: PiholeDisableActivityAttributes(), content: content)
        } catch {
            Log.widget.error("Failed to start Live Activity: \(String(describing: error), privacy: .public)")
        }
    }

    func end() async {
        for activity in Activity<PiholeDisableActivityAttributes>.activities {
            // Apple: include a final content update when ending, otherwise the
            // activity can remain visible until the system/person removes it.
            let finalContent = ActivityContent(state: activity.content.state, staleDate: nil)
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }

    func endExpired(asOf now: Date) {
        Task {
            for activity in Activity<PiholeDisableActivityAttributes>.activities
            where activity.content.state.endDate <= now {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
