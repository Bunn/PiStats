//
//  PreferencesViewController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import Preferences
import SwiftUI

/*
 I've decided to use this third party library (Preferences)
 because there's an annoying bug with SwiftUI TabBar + List
 that breaks the rendering and state of the selected item
 More info here:
 https://twitter.com/fcbunn/status/1269301540923363333?s=21
 */

private enum PaneIdentifier: String {
    case piholes
    case preferences
    case about
}

class PreferencesViewController {
    let piholeListViewModel: PiholeListViewModel
    let preferences: UserPreferences
    
    init(preferences: UserPreferences, piholeListViewModel: PiholeListViewModel) {
        self.preferences = preferences
        self.piholeListViewModel = piholeListViewModel
    }
    
    lazy var preferencesWindowController = PreferencesWindowController(
        panes: [
            Preferences.Pane(
                identifier: Preferences.PaneIdentifier(rawValue: PaneIdentifier.piholes.rawValue),
                title: UIConstants.Strings.preferencesPiholesTabTitle,
                toolbarIcon: NSImage(named: NSImage.userAccountsName)!
            ) {
                PiholeListConfigView(piholeListViewModel: piholeListViewModel)
            },
            
            Preferences.Pane(
                identifier: Preferences.PaneIdentifier(rawValue: PaneIdentifier.preferences.rawValue),
                title: UIConstants.Strings.preferencesPreferencesTabTitle,
                toolbarIcon: NSImage(named: NSImage.preferencesGeneralName)!
            ) {
                PreferencesView().environmentObject(self.preferences)
            },
            
            Preferences.Pane(
                identifier: Preferences.PaneIdentifier(rawValue: PaneIdentifier.about.rawValue),
                title: UIConstants.Strings.preferencesAboutTabTitle,
                toolbarIcon: NSImage(named: NSImage.applicationIconName)!
            ) {
                AboutView()
            }
        ], animated: false
    )
    
    func show() {
        preferencesWindowController.show()
    }
}
