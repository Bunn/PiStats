//
//  ContentView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settingsStore = SettingsStore(userDefaults: UserDefaults.shared())
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            PiholeListView(settingsStore: settingsStore)
                .tabItem {
                    Image(systemName: "shield")
                    Text("Pi-holes")
                }
                .tag(0)

            WatchSettingsView(settingsStore: settingsStore)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(1)
        }
        .onChange(of: scenePhase) { newPhase in
            // Battery optimization: stop polling when app is backgrounded
            // This will be handled in PiholeListView
        }
    }
}

#Preview {
    ContentView()
}
