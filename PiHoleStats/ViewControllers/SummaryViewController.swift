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
    let navigationItem = NavigationViewModel()
    let settings = Settings()
    lazy var dataViewModel: PiHoleViewModel = {
        let p = PiHoleViewModel(settings: settings)
        return p
    }()
    
    override func loadView() {
        view = NSView()
        preferredContentSize = NSSize(width: 320, height: 208)
        let contentView = ContentView()
            .environmentObject(navigationItem)
            .environmentObject(settings)
            .environmentObject(dataViewModel)
        
        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.width, .height]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        dataViewModel.startPolling()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        dataViewModel.stopPolling()
    }
}
