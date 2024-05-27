//
//  AppDelegate.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/27/24.
//

import Foundation
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem!
    private var windowController: StatusBarMenuWindowController?


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("potato")
        setupStatusItem()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 28)
        statusItem.button?.action = #selector(toggleUIVisible)
        statusItem.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "")
    }

    @objc func toggleUIVisible(_ sender: Any?) {
        if windowController == nil || windowController?.window?.isVisible == false {
            showUI(sender: sender)
        } else {
            hideUI()
        }
    }

    @objc func hideUI() {
       // backgroundService.startPolling()
        windowController?.close()
    }

    func showUI(sender: Any?) {
        //backgroundService.stopPolling()

        if windowController == nil {
            windowController = StatusBarMenuWindowController(
                statusItem: statusItem,
                contentViewController: MenuContentViewController()
            )
        }

        windowController?.showWindow(sender)
    }
}
