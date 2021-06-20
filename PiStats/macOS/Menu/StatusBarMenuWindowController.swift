//
//  StatusBarMenuWindowController.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import Foundation
import Cocoa
import os.log

//https://github.com/insidegui/CustomStatusBarWindow

final class StatusBarMenuWindowController: NSWindowController {
    
    private let log = OSLog(subsystem: String(describing: StatusBarMenuWindowController.self),
                            category: String(describing: StatusBarMenuWindowController.self))
    
    let statusItem: NSStatusItem?
    
    var windowWillClose: () -> Void = { }

    init(statusItem: NSStatusItem?, contentViewController: NSViewController) {
        self.statusItem = statusItem
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 344, height: 320),
            styleMask: [.fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: statusItem?.button?.window?.screen
        )
        
        window.isMovable = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.level = .statusBar
        window.contentViewController = contentViewController

        // This doesn't look quite right on macOS < 11, hence the conditional.
        if #available(macOS 11.0, *) {
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        
        super.init(window: window)
        window.delegate = self
        setupContentSizeObservation()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private var eventMonitor: EventMonitor?
    
    /// Posting this notification causes the system Menu Bar to stay put when the cursor leaves its area while over a full screen app.
    private func postBeginMenuTrackingNotification() {
        DistributedNotificationCenter.default().post(name: .init("com.apple.HIToolbox.beginMenuTrackingNotification"), object: nil)
    }
    
    /// Posting this notification reverses the effect of the notification above.
    private func postEndMenuTrackingNotification() {
        DistributedNotificationCenter.default().post(name: .init("com.apple.HIToolbox.endMenuTrackingNotification"), object: nil)
    }
    
    override func showWindow(_ sender: Any?) {
        postBeginMenuTrackingNotification()
        
        // Nasty, but necessary so that when our menu window shows up,
        // other windows from Menu Bar items go away.
        NSApp.activate(ignoringOtherApps: true)

        repositionWindow()
        
        window?.alphaValue = 1
        
        super.showWindow(sender)
        
        startMonitoringClicks()
    }
    
    private func startMonitoringClicks() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: { [weak self] _ in
            guard let self = self else { return }
            self.close()
        })
        eventMonitor?.start()
    }
    
    override func close() {
        postEndMenuTrackingNotification()
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.completionHandler = {
            super.close()
            
            self.eventMonitor?.stop()
            self.eventMonitor = nil
        }
        window?.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }
    
    // MARK: - Positioning relative to status item
    
    private struct Metrics {
        static let margin: CGFloat = 5
    }
    
    @objc func repositionWindow() {
        guard let referenceWindow = statusItem?.button?.window, let window = window else {
            os_log("Couldn't find reference window for repositioning status bar menu window, centering instead", log: self.log, type: .debug)
            self.window?.center()
            return
        }
        
        let width = contentViewController?.preferredContentSize.width ?? window.frame.width
        let height = contentViewController?.preferredContentSize.height ?? window.frame.height
        var x = referenceWindow.frame.origin.x + referenceWindow.frame.width / 2 - window.frame.width / 2
        
        if let screen = referenceWindow.screen {
            // If the window extrapolates the limits of the screen, reposition it.
            if (x + width) > (screen.visibleFrame.origin.x + screen.visibleFrame.width) {
                x = (screen.visibleFrame.origin.x + screen.visibleFrame.width) - width - Metrics.margin
            }
        }
        
        let rect = NSRect(
            x: x,
            y: referenceWindow.frame.origin.y - height - Metrics.margin,
            width: width,
            height: height
        )
        
        window.setFrame(rect, display: true, animate: false)
    }
    
    // MARK: - Auto size/position based on content controller
    
    private var contentSizeObservation: NSKeyValueObservation?
    
    override var contentViewController: NSViewController? {
        didSet {
            setupContentSizeObservation()
        }
    }
    
    private var previouslyObservedContentSize: NSSize?
    
    private func setupContentSizeObservation() {
        contentSizeObservation?.invalidate()
        contentSizeObservation = nil
        
        guard let controller = contentViewController else { return }
        
        contentSizeObservation = controller.observe(\.preferredContentSize, options: [.initial, .new]) { [weak self] controller, _ in
            self?.updateForNewContentSize(from: controller)
        }
    }
    
    private func updateForNewContentSize(from controller: NSViewController) {
        defer { previouslyObservedContentSize = controller.preferredContentSize }
        
        guard controller.preferredContentSize != previouslyObservedContentSize else { return }
        
        repositionWindow()
    }

}

// MARK: - Window delegate

extension StatusBarMenuWindowController: NSWindowDelegate {
    
    func windowWillClose(_ notification: Notification) {
        windowWillClose()
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        statusItem?.button?.highlight(true)
    }
    
    func windowDidResignKey(_ notification: Notification) {
        statusItem?.button?.highlight(false)
    }
    
}

final class StatusBarFlowBackgroundView: NSView {
    private lazy var vfxView: NSVisualEffectView = {
        let v = NSVisualEffectView(frame: bounds)
        v.autoresizingMask = [.width, .height]
        v.material = .windowBackground
        v.blendingMode = .behindWindow
        return v
    }()
    override var wantsUpdateLayer: Bool { true }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setup()
    }
    required init?(coder: NSCoder) {
        fatalError()
    }
    private func setup() {
        vfxView.frame = bounds
        addSubview(vfxView)
        layer?.masksToBounds = true
        layer?.cornerRadius = 14
        if #available(macOS 10.15, *) {
            layer?.cornerCurve = .continuous
        }
    }
}
