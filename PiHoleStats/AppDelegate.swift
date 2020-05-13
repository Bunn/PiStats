//
//  AppDelegate.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import SwiftUI
import SwiftHole

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var window: NSWindow!
    private lazy var popover = NSPopover()
    private var summaryViewController = SummaryViewController()
    
    private var buttonImage: NSImage? {
        let image = NSImage(named: .init("piHole"))
        image?.isTemplate = true
        return image
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        popover.contentViewController = summaryViewController
        updateButton()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    private func updateButton() {
        guard let button = statusItem.button else { return }
        button.image = buttonImage
        button.image?.size = NSSize(width: 20, height: 20)
        button.action = #selector(togglePopover)
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        guard let button = statusItem.button else { return }

        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: NSRectEdge.minY
        )
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
    }

}

