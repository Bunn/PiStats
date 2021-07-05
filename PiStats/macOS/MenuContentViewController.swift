//
//  MenuContentViewController.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/07/2021.
//

import Cocoa
import Combine
import PiStatsCore
import SwiftUI

final class MenuContentViewController: NSViewController {
    private var cancellables = Set<AnyCancellable>()

    let summaryModel: StatusBarSummaryViewModel
    var hasMonitorEnabled = false
    
    internal init() {

        let pihole1 = Pihole(address: "10.0.0.113", apiToken: "")
        pihole1.hasPiMonitor = true
        
        self.summaryModel = StatusBarSummaryViewModel([pihole1,
                                                     Pihole(address: "10.0.0.218", apiToken: "")])
        super.init(nibName: nil, bundle: nil)
        updateContentSize()
    }

    private func updateContentSize() {
        self.preferredContentSize =  NSSize(width: 320, height: hasMonitorEnabled ? 250 : 200)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = StatusBarFlowBackgroundView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        let contentView = StatusBarSummaryView()
            .environmentObject(summaryModel)
        
        let hostingController = NSHostingController(rootView: contentView)
        addChild(hostingController)
        hostingController.view.autoresizingMask = [.width, .height]
        hostingController.view.frame = view.bounds
        view.addSubview(hostingController.view)

        setupSizeCancellable()
    }
    
    private func setupSizeCancellable() {
        summaryModel.$hasMonitorEnabed.sink { hasMonitorEnabled in
            self.hasMonitorEnabled = hasMonitorEnabled
            self.updateContentSize()
        }.store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryModel.startPolling()
    }
}
