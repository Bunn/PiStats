//
//  DisablePickerView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI
import PiStatsCore

struct DisablePickerView: View {
    @ObservedObject var updater: PiholeSummaryDataUpdater
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @State private var isDisabling = false
    @State private var showCustomPicker = false

    var body: some View {
        List {
            // Predefined durations
            ForEach(settingsStore.customDisableTimes) { time in
                Button {
                    disableWithDuration(seconds: time.seconds)
                } label: {
                    HStack {
                        Text(time.displayName)
                            .foregroundColor(.primary)
                        Spacer()
                        if isDisabling {
                            ProgressView()
                        }
                    }
                }
                .disabled(isDisabling)
            }

            // Custom duration
            NavigationLink {
                CustomTimePickerView(
                    updater: updater,
                    onDismiss: {
                        dismiss()
                    }
                )
            } label: {
                Label("Custom", systemImage: "clock")
            }
            .disabled(isDisabling)

            // Permanently disable
            Button {
                disableWithDuration(seconds: nil)
            } label: {
                HStack {
                    Text("Permanently")
                        .foregroundColor(.red)
                    Spacer()
                    if isDisabling {
                        ProgressView()
                    }
                }
            }
            .disabled(isDisabling)
        }
        .navigationTitle("Disable Pi-hole")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func disableWithDuration(seconds: Int?) {
        isDisabling = true

        Task {
            if let seconds = seconds {
                await updater.disable(timer: seconds)
            } else {
                await updater.disable()
            }

            await MainActor.run {
                isDisabling = false
                dismiss()
            }
        }
    }
}

// MARK: - Custom Time Picker View

struct CustomTimePickerView: View {
    @ObservedObject var updater: PiholeSummaryDataUpdater
    let onDismiss: () -> Void

    @State private var hours: Int = 0
    @State private var minutes: Int = 5
    @State private var seconds: Int = 0
    @State private var isDisabling = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Duration")
                .font(.headline)

            // Time pickers
            HStack(spacing: 8) {
                Picker("Hours", selection: $hours) {
                    ForEach(0..<24) { hour in
                        Text("\(hour)h").tag(hour)
                    }
                }
                .frame(width: 60)
                .labelsHidden()

                Picker("Minutes", selection: $minutes) {
                    ForEach(0..<60) { minute in
                        Text("\(minute)m").tag(minute)
                    }
                }
                .frame(width: 60)
                .labelsHidden()

                Picker("Seconds", selection: $seconds) {
                    ForEach(0..<60) { second in
                        Text("\(second)s").tag(second)
                    }
                }
                .frame(width: 60)
                .labelsHidden()
            }

            // Confirm button
            Button {
                disableWithCustomTime()
            } label: {
                if isDisabling {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Disable")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.statusOffline)
            .disabled(totalSeconds == 0 || isDisabling)
        }
        .padding()
    }

    private var totalSeconds: Int {
        (hours * 3600) + (minutes * 60) + seconds
    }

    private func disableWithCustomTime() {
        guard totalSeconds > 0 else { return }

        isDisabling = true

        Task {
            await updater.disable(timer: totalSeconds)

            await MainActor.run {
                isDisabling = false
                onDismiss()
            }
        }
    }
}

#Preview {
    NavigationStack {
        DisablePickerView(
            updater: PiholeSummaryDataUpdater(
                pihole: Pihole(
                    name: "Pi-hole",
                    address: "192.168.1.100",
                    version: .v5,
                    port: 80,
                    secure: false,
                    token: nil,
                    piMonitor: nil,
                    uuid: UUID()
                )
            ),
            settingsStore: SettingsStore(userDefaults: UserDefaults.shared())
        )
    }
}
