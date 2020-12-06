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
    private lazy var navigationController = NavigationController(preferences: preferences, piholeDataProvider: dataProvider)
    private lazy var dataProvider = PiholeDataProvider(piholes: Pihole.restoreAll())
    private lazy var summaryViewController = SummaryViewController(preferences: preferences, piHoleDataProvider: dataProvider, navigationController: navigationController)
    private var globalEventMonitor: EventMonitor?
    private var localEventMonitor: EventMonitor?
    private var eventCancellable: AnyCancellable?
    private var statusPreferenceCancellable: AnyCancellable?
    private var statusCancellable: AnyCancellable?
    private lazy var iconStatusBadgeView: NSView = {
        let v = NSView(frame: .zero)
        v.wantsLayer = true
        return v
    }()
    
    private var buttonImage: NSImage? {
        let image = NSImage(named: .init("shield"))
        image?.isTemplate = true
        return image
    }
    
    public func setup() {
        updateButton()
        popover.contentViewController = summaryViewController
        setupEventMonitors()
        dataProvider.startPolling()
        dataProvider.updatePollingMode(.background)
        updateButtonStatus()
        setupCancellables()
    }
    
    private func setupCancellables() {
        eventCancellable = preferences.$keepPopoverPanelOpen.receive(on: DispatchQueue.main).sink { [weak self] keepPopoverOpen in
            if keepPopoverOpen {
                self?.globalEventMonitor?.stop()
                self?.localEventMonitor?.stop()
            } else {
                self?.globalEventMonitor?.start()
                self?.localEventMonitor?.start()
            }
        }
        statusPreferenceCancellable = preferences.$displayStatusColorWhenPiholeIsOffline.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updateButtonStatus()
        }
        
        statusCancellable = dataProvider.$status.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updateButtonStatus()
        }
    }
    
    private func setupEventMonitors() {
        globalEventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], scope: .global) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
        
        localEventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], scope: .local) { [weak self] event in
            guard let self = self else { return }
            
            let popoverWindow = self.popover.contentViewController?.view.window
            
            if event?.window != popoverWindow && self.popover.isShown {
                self.closePopover(sender: event)
            }
        }
    }
    
    private func destroyEventMonitor() {
        globalEventMonitor?.stop()
        globalEventMonitor = nil
        
        localEventMonitor?.stop()
        localEventMonitor = nil
    }
    
    private func updateButtonStatus() {
        if !preferences.displayStatusColorWhenPiholeIsOffline || dataProvider.status == .allEnabled {
            iconStatusBadgeView.removeFromSuperview()
            return
        }
        
        guard let button = statusItem.button else { return }
        let size: CGFloat = 6
        let badgeX = (button.frame.width / 2) - (size / 2)
        let badgeY = (button.frame.height / 2) - (size / 2)
        iconStatusBadgeView.frame = NSRect(x: badgeX, y: badgeY, width: size, height: size)
        iconStatusBadgeView.layer?.cornerRadius = size / 2
        if dataProvider.status == .allDisabled {
            iconStatusBadgeView.layer?.backgroundColor = UIConstants.NSColors.disabled?.cgColor
        } else if dataProvider.status == .enabledAndDisabled {
            iconStatusBadgeView.layer?.backgroundColor = UIConstants.NSColors.enabledAndDisabled?.cgColor
        }
        
        button.addSubview(iconStatusBadgeView)
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
            globalEventMonitor?.start()
            localEventMonitor?.start()
        }
        
        popover.show(
            relativeTo: button.bounds,
            of: button,
            preferredEdge: NSRectEdge.minY
        )
        dataProvider.updatePollingMode(.foreground)
    }
    
    private func closePopover(sender: Any?) {
        popover.performClose(sender)
        globalEventMonitor?.stop()
        localEventMonitor?.stop()
        dataProvider.updatePollingMode(.background)

    }
}
