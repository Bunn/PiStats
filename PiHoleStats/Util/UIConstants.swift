//
//  UIConstants.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 11/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftUI

struct UIConstants {
    
    struct Geometry {
        static let circleSize: CGFloat = 10.0
    }
    
    struct Colors {
        static let offline = Color("offline")
        static let active = Color("active")
        static let totalQuery = Color("totalQuery")
        static let domainBlocked = Color("domainBlocked")
        static let queryBlocked = Color("queryBlocked")
        static let percentBlocked = Color("percentBlocked")
    }
    
    struct Strings {
        
        struct Error {
            static let invalidAPIToken = "Invalid API Token"
            static let invalidResponse = "Invalid Response"
            static let invalidURL = "Invalid URL"
            static let decodeResponseError = "Can't decode response"
            static let noAPITokenProvided = "No API Token Provided"
            static let sessionError = "Session Error"
        }
        
        static let totalQueries = "Total Queries"
        static let queriesBlocked = "Queries Blocked"
        static let percentBlocked = "Percent Blocked"
        static let domainsOnBlocklist = "Domains on Blocklist"
        static let buttonPreferences = "Preferences"
        static let buttonOK = "OK"
        static let buttonQuit = "Quit"
        static let statusEnabled = "Active"
        static let statusDisabled = "Offline"
        static let buttonEnable = "Enable"
        static let buttonDisable = "Disable"
        static let host = "Host"
        static let hostPlaceholder = "0.0.0.0"
        static let apiToken = "API Token"
        static let apiTokenPlaceholder = "token"
        static let buttonClose = "Close"
        static let findAPITokenInfo = "You can find the API Token on /etc/pihole/setupVars.conf under WEBPASSWORD or WebUI - Settings - API - Show API Token"
        static let openSettingsToConfigureHost = "Open Settings to configure your host address"
        static let tokenStoredOnKeychainInfo = "Token is securely stored in your Mac's Keychain"
        static let copyright = "Copyright © Fernando Bunn"
        static let aboutTabTitle = "About"
        static let version = "Version"
        static let piStatsName = "Pi Stats"
        static let piHoleTabTitle = "Pi Hole"
        static let preferencesTabTitle = "Preferences"
        static let keepPopoverOpenPreference = "Keep popover open when clicking outside"
    }
}
