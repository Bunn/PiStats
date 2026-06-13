import SwiftUI
import PiStatsCore

struct MacSettingsView: View {
    @ObservedObject var prefs: MacPreferences
    @Environment(\.dismiss) private var dismiss
    @State private var alertSettings = AlertSettingsStore.load()

    @ViewBuilder
    private func notificationToggle(_ title: String, kind: AlertKind) -> some View {
        Toggle(title, isOn: Binding(
            get: { alertSettings.isEnabled(kind) },
            set: { alertSettings.setEnabled($0, for: kind) }
        ))
        .toggleStyle(.switch)
    }

    var body: some View {
        VStack (alignment: .leading) {
                Picker("Temperature Scale", selection: $prefs.temperatureScale) {
                    ForEach(TemperatureScale.allCases, id: \.self) { scale in
                        Text(scale.displayName).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle(isOn: $prefs.disablePermanently) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(UserText.Settings.alwaysDisablePermanentlyToggle)
                        Text(UserText.Settings.alwaysDisablePermanentlyDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                
                Toggle(UserText.Settings.startAtLoginToggle, isOn: $prefs.startAtLogin)
                    .toggleStyle(.switch)

                Divider()

                Toggle("Enable notifications", isOn: $alertSettings.masterEnabled)
                    .toggleStyle(.switch)
                if alertSettings.masterEnabled {
                    notificationToggle("Pi-hole offline", kind: .unreachable)
                    notificationToggle("Back online", kind: .recovered)
                    notificationToggle("Blocking disabled", kind: .blockingDisabled)
                    notificationToggle("Update available", kind: .updateAvailable)
                    notificationToggle("Diagnostic messages", kind: .ftlMessage)
                }

            HStack {
                Spacer()
                Button(UserText.doneButton) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: alertSettings) { _, newValue in
            AlertSettingsStore.save(newValue)
            if newValue.masterEnabled {
                Task { _ = await LocalNotificationDispatcher().requestAuthorizationIfNeeded() }
            }
        }
    }
}

#Preview {
    MacSettingsView(prefs: MacPreferences())
}
