//
//  NavigationController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa

class NavigationController: ObservableObject {
    private var windowController: NSWindowController?
    let preferences: UserPreferences
    let piholeListProvider: PiholeListProvider
    
    init(preferences: UserPreferences, piholeListProvider: PiholeListProvider) {
        self.preferences = preferences
        self.piholeListProvider = piholeListProvider
    }
    
    public func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        let controller = PreferencesViewController(preferences: preferences, piholeListProvider: piholeListProvider)
        controller.show()
//        
//        let settings = PreferencesViewController(preferences: preferences, piholeListProvider: piholeListProvider)
//        let window = NSWindow(contentViewController: settings)
//        windowController = NSWindowController(window: window)
//        windowController?.showWindow(self)
//        windowController?.window?.makeKey()
    }
}
