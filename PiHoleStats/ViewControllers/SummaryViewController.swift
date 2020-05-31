//
//  SummaryViewController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 10/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import SwiftUI

class SummaryViewController: NSViewController {
    private let preferences: Preferences
    private let navigationController: NavigationController
    private let piHoleDataProvider: PiholeDataProvider

    init(preferences: Preferences, piHoleDataProvider: PiholeDataProvider, navigationController: NavigationController) {
        self.preferences = preferences
        self.piHoleDataProvider = piHoleDataProvider
        self.navigationController = navigationController
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView()
        preferredContentSize = NSSize(width: 320, height: 208)
        let contentView = SummaryView()
            .environmentObject(navigationController)
            .environmentObject(preferences)
            .environmentObject(piHoleDataProvider)
        
        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.width, .height]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        piHoleDataProvider.startPolling()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        piHoleDataProvider.stopPolling()
    }
}
