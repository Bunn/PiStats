//
//  iOSApp.swift
//  iOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import WidgetKit

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    updateAllWidgets()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    updateAllWidgets()
                    DisableActivityController().endExpired(asOf: Date())
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    updateAllWidgets()
                    DisableActivityController().endExpired(asOf: Date())
                }
        }
    }

    private func updateAllWidgets() {
        Task {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}
