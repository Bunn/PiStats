//
//  macOSApp.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore

extension Notification.Name {
    static let showAddPiholeSheet = Notification.Name("dev.bunn.PiStats.showAddPiholeSheet")
}

@main
struct macOSApp: App {
    @StateObject private var prefs = MacPreferences()
    @StateObject private var dataManager = PiholeDataManager()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(dataManager: dataManager, prefs: prefs)
                .frame(minWidth: LayoutConstants.App.menuBarExtraMinWidth)
        } label: {
            MenuBarIconView(dataManager: dataManager)
                .task {
                    dataManager.startUpdating()
                }
        }
        .menuBarExtraStyle(.window)

        WindowGroup(UserText.MenuBar.appName, id: AppIdentifiers.mainWindowSceneId) {
            MacMainView(prefs: prefs, dataManager: dataManager)
                .frame(
                    minWidth: LayoutConstants.App.windowMinWidth,
                    maxWidth: LayoutConstants.App.windowMaxWidth,
                    minHeight: LayoutConstants.App.windowMinHeight,
                    maxHeight: LayoutConstants.App.windowMaxHeight,
                )
        }
        .windowResizability(.contentSize)

        .commands {
            CommandMenu("Pi-hole") {
                Button(UserText.Commands.addPiholeMenu) {
                    NotificationCenter.default.post(name: .showAddPiholeSheet, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
