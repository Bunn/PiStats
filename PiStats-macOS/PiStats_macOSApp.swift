//
//  PiStats_macOSApp.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/15/24.
//

import SwiftUI

@main
struct PiStats_macOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("menuBarExtraIsInserted") var menuBarExtraIsInserted = true

    var body: some Scene {
        MenuBarExtra("Screenshots",
                     systemImage: "photo.badge.plus",
                     isInserted: $menuBarExtraIsInserted) {
            PopoverView()
        }
                     .menuBarExtraStyle(.window)

        WindowGroup {
            ContentView()
        }
    }
}
