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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
