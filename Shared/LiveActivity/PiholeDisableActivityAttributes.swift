//
//  PiholeDisableActivityAttributes.swift
//  PiStats
//
//  Shared between the iOS app and the widget extension. Describes the
//  "blocking paused" Live Activity. iOS only (ActivityKit Live Activities are
//  not available on macOS).
//

import ActivityKit
import Foundation

struct PiholeDisableActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        /// When blocking automatically re-enables.
        var endDate: Date
    }

    var piholeID: String
    var piholeName: String
}
