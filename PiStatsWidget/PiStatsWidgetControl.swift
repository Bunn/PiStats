//
//  PiStatsWidgetControl.swift
//  PiStatsWidget
//
//  Control Center / Lock Screen controls for Pi-hole: a blocking toggle and a
//  quick-disable button that pauses blocking for a set time and starts a Live
//  Activity countdown.
//

import AppIntents
import SwiftUI
import WidgetKit
import PiStatsCore

// MARK: - Blocking toggle control

struct PiStatsWidgetControl: ControlWidget {
    static let kind = "dev.bunn.PiStatsMobile.PiholeToggle"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: Provider()) { value in
            ControlWidgetToggle("Pi-hole",
                                isOn: value.isEnabled,
                                action: SetBlockingIntent()) { isOn in
                Label(isOn ? "Blocking" : "Paused", systemImage: isOn ? "checkmark.shield.fill" : "xmark.shield.fill")
            }
        }
        .displayName("Pi-hole Blocking")
        .description("Toggle ad blocking for all your Pi-holes.")
    }
}

extension PiStatsWidgetControl {
    struct Value {
        var isEnabled: Bool
    }

    struct Provider: ControlValueProvider {
        var previewValue: Value { Value(isEnabled: true) }

        func currentValue() async throws -> Value {
            let piholes = widgetPiholeStorage.restoreAllPiholes()
            let allEnabled = await PiholeActionService().areAllEnabled(piholes)
            return Value(isEnabled: allEnabled)
        }
    }
}

struct SetBlockingIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Set Pi-hole Blocking"
    @Parameter(title: "Enabled") var value: Bool

    init() {}

    func perform() async throws -> some IntentResult {
        let piholes = widgetPiholeStorage.restoreAllPiholes()
        guard !piholes.isEmpty else { throw IntentError.message("No Pi-holes configured") }
        let service = PiholeActionService()
        if value {
            try await service.enableAll(piholes)
        } else {
            try await service.disableAll(piholes, timer: nil)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "PiStatusControlWidget")
        return .result()
    }
}

// MARK: - Quick-disable control (starts a Live Activity)

struct PiholeQuickDisableControl: ControlWidget {
    static let kind = "dev.bunn.PiStatsMobile.PiholeQuickDisable"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(kind: Self.kind, provider: QuickDisableProvider()) { value in
            ControlWidgetButton(action: QuickDisableIntent(seconds: value.seconds)) {
                Label("Disable \(value.label)", systemImage: "xmark.shield")
            }
        }
        .displayName("Pi-hole Quick Disable")
        .description("Pause blocking on all your Pi-holes for a set time.")
    }
}

extension PiholeQuickDisableControl {
    struct Value {
        var seconds: Int
        var label: String
    }

    struct QuickDisableProvider: AppIntentControlValueProvider {
        func previewValue(configuration: QuickDisableConfiguration) -> Value {
            Value(seconds: configuration.seconds, label: configuration.label)
        }

        func currentValue(configuration: QuickDisableConfiguration) async throws -> Value {
            Value(seconds: configuration.seconds, label: configuration.label)
        }
    }
}

struct QuickDisableConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Quick Disable Configuration"
    @Parameter(title: "Duration (minutes)", default: 5) var minutes: Int

    var seconds: Int { max(1, minutes) * 60 }
    var label: String { "\(max(1, minutes))m" }
}
