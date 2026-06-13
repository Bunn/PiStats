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
        AppIntentControlConfiguration(kind: Self.kind, provider: Provider()) { value in
            ControlWidgetToggle("Pi-hole",
                                isOn: value.isEnabled,
                                action: SetBlockingIntent(piholeId: value.piholeId)) { isOn in
                Label(isOn ? "Blocking" : "Paused", systemImage: isOn ? "checkmark.shield.fill" : "xmark.shield.fill")
            }
        }
        .displayName("Pi-hole Blocking")
        .description("Toggle ad blocking for your Pi-hole.")
    }
}

extension PiStatsWidgetControl {
    struct Value {
        var isEnabled: Bool
        var piholeId: String
    }

    struct Provider: AppIntentControlValueProvider {
        func previewValue(configuration: PiholeControlConfiguration) -> Value {
            Value(isEnabled: true, piholeId: configuration.pihole?.id ?? "")
        }

        func currentValue(configuration: PiholeControlConfiguration) async throws -> Value {
            guard let id = configuration.pihole?.id,
                  let uuid = UUID(uuidString: id),
                  let pihole = widgetPiholeStorage.restorePihole(uuid) else {
                return Value(isEnabled: false, piholeId: "")
            }
            let status = (try? await PiholeAPIClient(pihole).fetchStatus()) ?? .unknown
            return Value(isEnabled: status == .enabled, piholeId: id)
        }
    }
}

struct PiholeControlConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Pi-hole Control"
    @Parameter(title: "Pi-hole") var pihole: PiholeEntity?
}

struct SetBlockingIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Set Pi-hole Blocking"
    @Parameter(title: "Pi-hole ID") var piholeId: String
    @Parameter(title: "Enabled") var value: Bool

    init() {}
    init(piholeId: String) { self.piholeId = piholeId }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: piholeId),
              let pihole = widgetPiholeStorage.restorePihole(uuid) else {
            throw IntentError.message("Pi-hole not found")
        }
        let service = PiholeActionService()
        if value {
            _ = try await service.enable(pihole)
        } else {
            _ = try await service.disable(pihole, timer: nil)
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
            ControlWidgetButton(action: QuickDisableIntent(piholeId: value.piholeId, seconds: value.seconds)) {
                Label("Disable \(value.label)", systemImage: "xmark.shield")
            }
        }
        .displayName("Pi-hole Quick Disable")
        .description("Pause blocking for a set time.")
    }
}

extension PiholeQuickDisableControl {
    struct Value {
        var piholeId: String
        var seconds: Int
        var label: String
    }

    struct QuickDisableProvider: AppIntentControlValueProvider {
        func previewValue(configuration: QuickDisableConfiguration) -> Value {
            Value(piholeId: configuration.pihole?.id ?? "", seconds: configuration.seconds, label: configuration.label)
        }

        func currentValue(configuration: QuickDisableConfiguration) async throws -> Value {
            Value(piholeId: configuration.pihole?.id ?? "", seconds: configuration.seconds, label: configuration.label)
        }
    }
}

struct QuickDisableConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Quick Disable Configuration"
    @Parameter(title: "Pi-hole") var pihole: PiholeEntity?
    @Parameter(title: "Duration (minutes)", default: 5) var minutes: Int

    var seconds: Int { max(1, minutes) * 60 }
    var label: String { "\(max(1, minutes))m" }
}

struct QuickDisableIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Disable Pi-hole"
    @Parameter(title: "Pi-hole ID") var piholeId: String
    @Parameter(title: "Seconds") var seconds: Int

    init() {}
    init(piholeId: String, seconds: Int) { self.piholeId = piholeId; self.seconds = seconds }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: piholeId),
              let pihole = widgetPiholeStorage.restorePihole(uuid) else {
            throw IntentError.message("Pi-hole not found")
        }
        let service = PiholeActionService(onDisableWithTimer: { id, name, until in
            DisableActivityController().start(piholeID: id.uuidString, name: name, until: until)
        })
        _ = try await service.disable(pihole, timer: seconds)
        WidgetCenter.shared.reloadTimelines(ofKind: "PiStatusControlWidget")
        return .result()
    }
}
