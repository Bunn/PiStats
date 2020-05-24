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
    let preferences: Preferences

      init(preferences: Preferences) {
          self.preferences = preferences
      }
    
    public func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        let settings = PreferencesViewController(preferences: preferences)
        let window = NSWindow(contentViewController: settings)
        windowController = NSWindowController(window: window)
        windowController?.showWindow(self)
        windowController?.window?.makeKey()
    }
}
