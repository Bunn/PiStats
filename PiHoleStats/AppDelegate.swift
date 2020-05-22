//
//  AppDelegate.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    let menuController = MenuController()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        menuController.setup()
    }
}
