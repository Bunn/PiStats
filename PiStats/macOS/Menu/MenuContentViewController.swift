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
    private var preferencesWindow: NSWindow!
    private var cancellables = Set<AnyCancellable>()
    private let piholeManager: PiholeManager
    let summaryModel: StatusBarSummaryViewModel
    var hasMonitorEnabled = false
    
    internal init(piholeManager: PiholeManager) {
        self.piholeManager = piholeManager
        self.summaryModel = StatusBarSummaryViewModel(piholeManager.piholes)
        super.init(nibName: nil, bundle: nil)
        self.summaryModel.delegate = self
        self.updateContentSize()
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
        summaryModel.$hasMonitorEnabled.sink { hasMonitorEnabled in
            self.hasMonitorEnabled = hasMonitorEnabled
            self.updateContentSize()
        }.store(in: &cancellables)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        summaryModel.startPolling()
    }
    
    override func viewDidDisappear() {
        super.viewDidLoad()
        summaryModel.stopPolling()
    }
    
    private func openPreferencesWindow() {
        if preferencesWindow != nil {
            preferencesWindow.close()
            preferencesWindow = nil
        }
        
        let preferencesViewModal = PreferencesViewModel(piholeManager: piholeManager)
        let contentView = PreferencesView(viewModel: preferencesViewModal)

        // Create the window and set the content view.
        preferencesWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        preferencesWindow.isReleasedWhenClosed = false
        preferencesWindow.center()
        preferencesWindow.setFrameAutosaveName("Main Window")
        preferencesWindow.contentView = NSHostingView(rootView: contentView)
        preferencesWindow.toolbarStyle = .unifiedCompact
        preferencesWindow.makeKeyAndOrderFront(nil)
    }
}

extension MenuContentViewController: StatusBarSummaryViewModelDelegate {
    
    func statusBarSummaryViewModelWantsToOpenPreferences(_ viewModel: StatusBarSummaryViewModel) {
        openPreferencesWindow()
    }
}
