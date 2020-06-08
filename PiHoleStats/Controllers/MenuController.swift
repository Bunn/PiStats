//
//  MenuController.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa
import Combine

class MenuController: NSObject {
    private lazy var popover = NSPopover()
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let preferences = UserPreferences()
    private lazy var navigationController = NavigationController(preferences: preferences, piholeListProvider: piholeListProvider)
    private lazy var dataProvider: PiholeDataProvider = {
        let d = PiholeDataProvider(piholeListProvider: piholeListProvider)
        return d
    }()
    private let piholeListProvider = PiholeListProvider()
    private lazy var summaryViewController = SummaryViewController(preferences: preferences, piHoleDataProvider: dataProvider, navigationController: navigationController)
    var eventMonitor: EventMonitor?
    var eventCancellable: AnyCancellable?

    private var buttonImage: NSImage? {
        let image = NSImage(named: .init("shield"))
        image?.isTemplate = true
        return image
    }
    
    public func setup() {
        updateButton()
        popover.contentViewController = summaryViewController
        setupEventMonitor()
        
        eventCancellable = preferences.$keepPopoverPanelOpen.receive(on: DispatchQueue.main).sink { [weak self] keepPopoverOpen in
            if keepPopoverOpen {
                self?.eventMonitor?.stop()
            } else {
                self?.eventMonitor?.start()
            }
        }
    }
    
    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
    }
    
    private func destroyEventMonitor() {
        eventMonitor?.stop()
        eventMonitor = nil
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
        if !preferences.keepPopoverPanelOpen {
            eventMonitor?.start()
        }
        
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
