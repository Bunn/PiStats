//
//  ContentView.swift
//  iOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore
import PiStatsUI

struct ContentView: View {
    @StateObject private var settingsStore = SettingsStore(userDefaults: UserDefaults.shared())
    
    var body: some View {
        TabView {
            NavigationView {
                PiholeStatsList(settingsStore: settingsStore)
            }
            .tabItem {
                Image(systemName: "shield")
                Text(UserText.piholesNavigationTitle)
            }.tag(0)
            .navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                SettingsView(viewModel: settingsStore.settingsViewModel)
            }
            .tabItem {
                Image(systemName: "gear")
                Text(UserText.settingsNavigationTitle)
            }.tag(1)
            .navigationViewStyle(StackNavigationViewStyle())

        }
    }
}
#Preview {
    ContentView()
}
