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
    let piholeDataProvider: PiholeDataProvider
    
    lazy var preferencesController = PreferencesViewController(preferences: preferences, piholeListViewModel: PiholeListViewModel(piholeDataProvider: piholeDataProvider))
    
    init(preferences: UserPreferences, piholeDataProvider: PiholeDataProvider) {
        self.preferences = preferences
        self.piholeDataProvider = piholeDataProvider
    }
    
    public func openPreferences() {
        NSApp.activate(ignoringOtherApps: true)

        preferencesController.show()
    }
}
