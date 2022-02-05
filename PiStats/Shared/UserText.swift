//
//  UserText.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/02/2022.
//

import Foundation

struct UserText {
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
    
    static let preferencesQRCodeFormat = "QR Code Format:"
    static let preferencesQRCodeFormatWebInterface = "Web Interface"
    static let preferencesQRCodeFormatPiStats = "Pi Stats"
    static let preferencesQRCodeToolTip = "Display Pi-hole Settings as QR Code"
    static let preferencesWebToolTip = "Open Pi-hole Web Interface"

}
