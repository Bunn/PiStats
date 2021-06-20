//
//  AppDelegate.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import Cocoa
import SwiftUI
import PiStatsCore

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow!


    private var statusItem: NSStatusItem!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.button?.title = "🛑"
        statusItem.button?.action = #selector(toggleUIVisible)
    }
    
    private var windowController: StatusBarMenuWindowController?

    @objc func toggleUIVisible(_ sender: Any?) {
        if windowController == nil || windowController?.window?.isVisible == false {
            showUI(sender: sender)
        } else {
            hideUI()
        }
    }
    
    @objc func hideUI() {
        windowController?.close()
    }

    func showUI(sender: Any?) {
        if windowController == nil {
            windowController = StatusBarMenuWindowController(
                statusItem: statusItem,
                contentViewController: DummyContentViewController()
            )
        }
        
        windowController?.showWindow(sender)
    }
    
    @objc func openPreferencesWindow() {
        let contentView = NavigationContainerView()

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


final class DummyContentViewController: NSViewController {
    
    
    let summaryModel: StatusBarSummaryViewModel

    internal init() {

        let pihole1 = Pihole(address: "10.0.0.113")
        pihole1.hasPiMonitor = true
        
        
        self.summaryModel = StatusBarSummaryViewModel([pihole1,
                                                     Pihole(address: "10.0.0.218")])
        super.init(nibName: nil, bundle: nil)


    }
    
    override var preferredContentSize: NSSize {
        get {
            NSSize(width: 320, height: 250)
        }
        set {
            super.preferredContentSize = newValue
        }
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

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        summaryModel.startPolling()
    }
    
}
