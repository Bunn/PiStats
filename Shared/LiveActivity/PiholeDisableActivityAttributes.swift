//
//  PiholeDisableActivityAttributes.swift
//  PiStats
//
//  Shared between the iOS app and the widget extension. Describes the
//  "blocking paused" Live Activity. There is a single, global activity that
//  represents all Pi-holes being paused, so it carries no per-Pi-hole identity.
//  iOS only (ActivityKit Live Activities are not available on macOS).
//

import ActivityKit
import Foundation

struct PiholeDisableActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When blocking automatically re-enables.
        var endDate: Date
    }
}
