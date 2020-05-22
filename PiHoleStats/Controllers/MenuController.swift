//
//  MenuController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa

class MenuController: NSObject {
    private lazy var popover = NSPopover()
    private lazy var summaryViewController = SummaryViewController()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    var eventMonitor: EventMonitor?

    private var buttonImage: NSImage? {
        let image = NSImage(named: .init("shield"))
        image?.isTemplate = true
        return image
    }
    
    public func setup() {
        updateButton()
        popover.contentViewController = summaryViewController
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }
    
    private func updateButton() {
        guard let button = statusItem.button else { return }
        button.image = buttonImage
        button.image?.size = NSSize(width: 20, height: 20)
        button.action = #selector(togglePopover)
        button.target = self
    }
    
    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            closePopover(sender: sender)
        } else {
            showPopover(sender: sender)
        }
    }
    
    private func showPopover(sender: Any?) {
        guard let button = statusItem.button else { return }
        eventMonitor?.start()
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: NSRectEdge.minY
        )
    }
    
    private func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}
