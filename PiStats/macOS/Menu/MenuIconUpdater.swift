//
//  MenuIconUpdater.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/07/2021.
//

import Cocoa
import PiStatsCore

struct MenuIconUpdater {
    static func update(statusItem: NSStatusItem, with piholeStatus: PiholeStatus) {
        switch piholeStatus {
        case .allEnabled:
            statusItem.button?.title = "🟢"
        case .allDisabled:
            statusItem.button?.title = "🛑"
        case .enabledAndDisabled:
            statusItem.button?.title = "⚠️"
        }
    }
}
