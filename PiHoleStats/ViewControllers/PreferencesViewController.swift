//
//  PreferencesViewController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import SwiftUI

class PreferencesViewController: NSViewController {
    let preferences = Preferences()
    let navigationItem = NavigationViewModel()
    
    override func loadView() {
        view = NSView()
        preferredContentSize = NSSize(width: 390, height: 300)
        let contentView = PreferencesView()
            .environmentObject(navigationItem)
            .environmentObject(preferences)
        
        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.width, .height]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
    }
}
