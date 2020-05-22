//
//  ViewNavigationModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 10/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine
import AppKit

enum NavigationItem {
    case summary
    case settings
}

class NavigationViewModel: ObservableObject {
    private var didChange = PassthroughSubject<Void, Never>()
    var windowController: NSWindowController?
    
    @Published var currentNavigationItem: NavigationItem = .summary {
        didSet {
            didChange.send()
        }
    }
    
    public func test() {
        NSApp.activate(ignoringOtherApps: true)
             let settings = PreferencesViewController()
             let window = NSWindow(contentViewController: settings)
             windowController = NSWindowController(window: window)
             windowController?.showWindow(self)
             windowController?.window?.makeKey()
    }
}
