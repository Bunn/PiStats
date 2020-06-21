//
//  Settings.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 11/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine

private enum PreferencesKey: String {
    case keepPopoverPanelOpen = "SettingsKeyKeepPopoverPanelOpen"
    case displayDisableTimeOptions = "SettingsDisplayDisableTimeOptions"
}

class UserPreferences: ObservableObject {
    var keychainToken = APIToken(accountName: "PiHoleStatsAccount")
    private var appURL: URL { Bundle.main.bundleURL }
    static let didChangeNotification = Notification.Name("dev.bunn.holestats.PrefsChanged")
    @Published private var _launchAtLoginEnabled: Bool = false
    
    init() {
        apiToken = keychainToken.token
    }
    
    @Published var keepPopoverPanelOpen: Bool = UserDefaults.standard.object(forKey: PreferencesKey.keepPopoverPanelOpen.rawValue) as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(keepPopoverPanelOpen, forKey: PreferencesKey.keepPopoverPanelOpen.rawValue)
        }
    }
    
    @Published var displayDisableTimeOptions: Bool = UserDefaults.standard.object(forKey: PreferencesKey.displayDisableTimeOptions.rawValue) as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(displayDisableTimeOptions, forKey: PreferencesKey.displayDisableTimeOptions.rawValue)
        }
    }
    
    @Published var apiToken: String {
        didSet {
            keychainToken.token = apiToken
        }
    }
    
    var launchAtLoginEnabled: Bool {
        get {
            _launchAtLoginEnabled || SharedFileList.sessionLoginItems().containsItem(appURL)
        }
        set {
            _launchAtLoginEnabled = newValue
            
            if newValue {
                SharedFileList.sessionLoginItems().addItem(appURL)
            } else {
                SharedFileList.sessionLoginItems().removeItem(appURL)
            }
            
            didChange()
        }
    }
    
    private func didChange() {
        NotificationCenter.default.post(name: Self.didChangeNotification, object: self)
    }
}
