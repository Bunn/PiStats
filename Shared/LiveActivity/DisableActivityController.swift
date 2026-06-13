//
//  DisableActivityController.swift
//  PiStats
//
//  Starts/ends the "blocking paused" Live Activity. iOS only.
//

import ActivityKit
import Foundation

struct DisableActivityController {
    /// Starts (or restarts) the countdown Live Activity for a Pi-hole.
    func start(piholeID: String, name: String, until: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end(piholeID: piholeID) // avoid stacking duplicates
        let attributes = PiholeDisableActivityAttributes(piholeID: piholeID, piholeName: name)
        let state = PiholeDisableActivityAttributes.ContentState(endDate: until)
        _ = try? Activity.request(attributes: attributes, content: .init(state: state, staleDate: until))
    }

    /// Ends any Live Activities for the given Pi-hole.
    func end(piholeID: String) {
        Task {
            for activity in Activity<PiholeDisableActivityAttributes>.activities where activity.attributes.piholeID == piholeID {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
