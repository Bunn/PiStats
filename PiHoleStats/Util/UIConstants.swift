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
        static let disabled = Color("disabled")
        static let enabled = Color("enabled")
        static let enabledAndDisabled = Color("enabledAndDisabled")
        static let totalQuery = Color("totalQuery")
        static let domainBlocked = Color("domainBlocked")
        static let queryBlocked = Color("queryBlocked")
        static let percentBlocked = Color("percentBlocked")
    }
    
    struct NSColors {
           static let disabled = NSColor(named: "disabled")
           static let enabledAndDisabled = NSColor(named: "enabledAndDisabled")
       }
    
    struct Images {
        static let globe = "globe"
        static let QRCode = "qrcode"
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
        static let statusNeedsAttention = "Needs Attention"
        static let statusEnabledAndDisabled = "Partially Active"
        static let buttonEnable = "Enable"
        static let buttonDisable = "Disable"
        static let host = "Host"
        static let hostPlaceholder = "0.0.0.0"
        static let apiToken = "API Token"
        static let preferencesProtocol = "Protocol"
        static let preferencesProtocolHTTP = "HTTP"
        static let preferencesProtocolHTTPS = "HTTPS"
        static let apiTokenPlaceholder = "token"
        static let buttonClose = "Close"
        static let findAPITokenInfo = "You can find the API Token on /etc/pihole/setupVars.conf under WEBPASSWORD or WebUI - Settings - API - Show API Token"
        static let openPreferencesToConfigureFirstPihole = "Open Preferences to configure your Pi-hole"
        static let tokenStoredOnKeychainInfo = "Your Pi-hole token is securely stored in your Mac's Keychain"
        static let copyright = "Copyright © Fernando Bunn"
        static let version = "Version"
        static let piStatsName = "Pi Stats"
        static let keepPopoverOpenPreference = "Keep popover open when clicking outside"
        static let launchAtLogonPreference = "Launch at login"
        static let preferencesWindowTitle = "Pi Stats Preferences"
        static let disableTimeOptionsTitle = "Display disable time options"
        static let displayStatusColorWhenPiholeIsOffline = "Display status color on menu bar icon when pi-hole is offline"
        static let disableButtonOptionPermanently = "Permanently"
        static let disableButtonOption30Seconds = "For 30 seconds"
        static let disableButtonOption1Minute = "For 1 minute"
        static let disableButtonOption5Minutes = "For 5 minutes"
        static let buttonClearErrorMessages = "Clear"
        static let preferencesPiholesTabTitle = "Pi-holes"
        static let preferencesPreferencesTabTitle = "Preferences"
        static let preferencesAboutTabTitle = "About"
        static let savePiholeButton = "Save"
        static let noSelectedPiholeMessage = "Select a pi-hole on the left or click Add to setup a new pi-hole"
        static let noAvailablePiholeToSelectMessage = "No pi-holes available, click Add to setup a new pi-hole"
        static let warningButton = "⚠️"
        static let openProjectWebsiteButton = "Project Website"
        static let piStatsForMobileButton = "Pi Stats Mobile"
        static let preferencesQRCodeFormat = "QR Code Format:"
        static let preferencesQRCodeFormatWebInterface = "Web Interface"
        static let preferencesQRCodeFormatPiStats = "Pi Stats"
        static let preferencesQRCodeToolTip = "Display Pi-hole Settings as QR Code"
        static let preferencesWebToolTip = "Open Pi-hole Web Interface"

    }
}
