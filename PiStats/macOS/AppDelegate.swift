//
//  AppDelegate.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import Cocoa
import SwiftUI
import PiStatsCore
import Combine

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    var preferencesWindow: NSWindow!
    var piholes = [Pihole]()
    private var cancellables = Set<AnyCancellable>()
    private var statusItem: NSStatusItem!
    private var backgroundService = BackgroundService()
    private var windowController: StatusBarMenuWindowController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusItem()
        setupPiholes()
    }

    @objc func toggleUIVisible(_ sender: Any?) {
        if windowController == nil || windowController?.window?.isVisible == false {
            showUI(sender: sender)
        } else {
            hideUI()
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.button?.action = #selector(toggleUIVisible)
    }
    
    private func setupPiholes() {
        let pihole1 = Pihole(address: "10.0.0.113", apiToken: "")
        pihole1.hasPiMonitor = true
        
        self.piholes = [pihole1,
                        Pihole(address: "10.0.0.218", apiToken: "")]
        
        backgroundService.piholes = piholes
        
        backgroundService.$status.sink { status in
            MenuIconUpdater.update(statusItem: self.statusItem, with: status)
        }.store(in: &cancellables)
        
        backgroundService.startPolling()
    }
    
    @objc func hideUI() {
        windowController?.close()
    }

    func showUI(sender: Any?) {
        if windowController == nil {
            windowController = StatusBarMenuWindowController(
                statusItem: statusItem,
                contentViewController: MenuContentViewController(piholes: piholes)
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
