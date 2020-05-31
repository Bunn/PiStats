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
    let piHoleController: PiholeController
    let preferences: Preferences
    
    init(preferences: Preferences, piHoleController: PiholeController) {
        self.preferences = preferences
        self.piHoleController = piHoleController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.Strings.preferencesWindowTitle
    }
    
    override func loadView() {
        view = NSView()
        preferredContentSize = NSSize(width: 510, height: 350)
        let contentView = PreferencesContainerView()
            .environmentObject(preferences)
            .environmentObject(piHoleController)
        
        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.width, .height]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
    }
}
