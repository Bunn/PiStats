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
    private var cancellables = Set<AnyCancellable>()
    private var statusItem: NSStatusItem!
    private var backgroundService = BackgroundService()
    private var windowController: StatusBarMenuWindowController?
    private let piholeManager = PiholeManager.shared

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
        backgroundService.piholes = piholeManager.piholes
        
        backgroundService.$status.sink { status in
            MenuIconUpdater.update(statusItem: self.statusItem, with: status)
        }.store(in: &cancellables)
        
        backgroundService.startPolling()
    }
    
    @objc func hideUI() {
        backgroundService.startPolling()
        windowController?.close()
    }

    func showUI(sender: Any?) {
        backgroundService.stopPolling()
        
        if windowController == nil {
            windowController = StatusBarMenuWindowController(
                statusItem: statusItem,
                contentViewController: MenuContentViewController(piholeManager: piholeManager)
            )
        }
        
        windowController?.showWindow(sender)
    }
    
}
