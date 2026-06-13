//
//  AlertSettingsStore.swift
//  PiStats
//
//  Persists AlertSettings in the shared app group so the app, widget and
//  Control Center control all read the same values.
//

import Foundation
import PiStatsCore

public enum AlertSettingsStore {
    private static let suite = AppGroup.name
    private static let key = "alertSettings"

    public static func load() -> AlertSettings {
        guard let defaults = UserDefaults(suiteName: suite),
              let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AlertSettings.self, from: data) else {
            return .default
        }
        return decoded
    }

    public static func save(_ settings: AlertSettings) {
        guard let defaults = UserDefaults(suiteName: suite),
              let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }
}
