//
//  WatchSettingsView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI

struct WatchSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: $settingsStore.displayStatsAsList) {
                        Label("Display as List", systemImage: SystemImages.settingsDisplayAsList)
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text("Show stats in a vertical list instead of a grid.")
                }

                Section {
                    Toggle(isOn: $settingsStore.disablePermanently) {
                        Label("Disable Permanently", systemImage: SystemImages.settingsDisablePermanently)
                    }
                } header: {
                    Text("Controls")
                } footer: {
                    Text("When off, tapping Disable will show duration options.")
                }

                Section {
                    Picker("Temperature", selection: $settingsStore.temperatureScale) {
                        Text("Celsius").tag(TemperatureScale.celsius)
                        Text("Fahrenheit").tag(TemperatureScale.fahrenheit)
                    }
                } header: {
                    Text("Units")
                }

                Section {
                    Text("Use iPhone to configure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Configuration")
                }

                Section {
                    NavigationLink("Debug Storage") {
                        DebugStorageView()
                    }
                } header: {
                    Text("Developer")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    WatchSettingsView(settingsStore: SettingsStore(userDefaults: UserDefaults.shared()))
}
