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
    @StateObject private var settingsStore: SettingsStore
    private let screenshotListUpdater: PiholeListUpdater?

    init() {
        let settingsStore = SettingsStore(userDefaults: UserDefaults.shared())
#if DEBUG
        if AppStoreScreenshotData.isEnabled {
            AppStoreScreenshotData.configure(settingsStore)
            screenshotListUpdater = AppStoreScreenshotData.makeListUpdater()
        } else {
            screenshotListUpdater = nil
        }
#else
        screenshotListUpdater = nil
#endif
        _settingsStore = StateObject(wrappedValue: settingsStore)
    }

    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadRootView(settingsStore: settingsStore, listUpdater: screenshotListUpdater)
        } else {
            iPhoneRootView(settingsStore: settingsStore, listUpdater: screenshotListUpdater)
        }
    }
}

private struct iPhoneRootView: View {
    @ObservedObject var settingsStore: SettingsStore
    let listUpdater: PiholeListUpdater?

    var body: some View {
        TabView {
            NavigationStack {
                PiholeStatsList(settingsStore: settingsStore, listUpdater: listUpdater)
            }
            .tabItem {
                Image(systemName: "shield")
                Text(UserText.piholesNavigationTitle)
            }.tag(0)

            NavigationStack {
                SettingsView(viewModel: settingsStore.settingsViewModel)
            }
            .tabItem {
                Image(systemName: "gear")
                Text(UserText.settingsNavigationTitle)
            }.tag(1)
        }
    }
}

private enum SidebarItem: Hashable {
    case piholes
    case settings
}

private struct iPadRootView: View {
    @ObservedObject var settingsStore: SettingsStore
    let listUpdater: PiholeListUpdater?
    @State private var selection: SidebarItem? = .piholes

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: SidebarItem.piholes) {
                    Label(UserText.piholesNavigationTitle, systemImage: "shield")
                }
                NavigationLink(value: SidebarItem.settings) {
                    Label(UserText.settingsNavigationTitle, systemImage: "gear")
                }
            }
            .navigationTitle("Pi Stats")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            switch selection ?? .piholes {
            case .piholes:
                NavigationStack {
                    PiholeStatsList(settingsStore: settingsStore, listUpdater: listUpdater)
                }
            case .settings:
                NavigationStack {
                    SettingsView(viewModel: settingsStore.settingsViewModel)
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    ContentView()
}
