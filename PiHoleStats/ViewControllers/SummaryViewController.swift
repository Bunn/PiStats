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
    
    lazy var dataViewModel: PiHoleViewModel = {
        let p = PiHoleViewModel(preferences: preferences)
        return p
    }()
    
    init(preferences: Preferences, navigationController: NavigationController) {
        self.preferences = preferences
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
