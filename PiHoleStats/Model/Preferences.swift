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
    case address = "SettingsKeyHost"
    case keepPopoverPanelOpen = "SettingsKeyKeepPopoverPanelOpen"
}

class Preferences: ObservableObject {
    var keychainToken = APIToken()
    
    init() {
        apiToken = keychainToken.token
    }
    
    @Published var keepPopoverPanelOpen: Bool = UserDefaults.standard.object(forKey: PreferencesKey.keepPopoverPanelOpen.rawValue) as? Bool ?? false {
        didSet {
            UserDefaults.standard.set(keepPopoverPanelOpen, forKey: PreferencesKey.keepPopoverPanelOpen.rawValue)
        }
    }
    
    @Published var address: String = UserDefaults.standard.object(forKey: PreferencesKey.address.rawValue) as? String ?? "" {
        didSet {
            UserDefaults.standard.set(address, forKey: PreferencesKey.address.rawValue)
        } 
    }
    
    @Published var apiToken: String  {
        didSet {
            keychainToken.token = apiToken
        }
    }
    
    var port: Int? {
        getPort(address)
    }
    
    var host: String {
        address.components(separatedBy: ":").first ?? ""
    }
    
    private func getPort(_ address: String) -> Int? {
        let split = address.components(separatedBy: ":")
        guard let port = split.last else { return nil }
        return Int(port)
    }
}
