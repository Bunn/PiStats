//
//  Settings.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 11/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine

private enum SettingsKey: String {
    case host = "SettingsKeyHost"
    case apiToken = "SettingsKeyAPIToken"
}

class Settings {
    private var didChange = PassthroughSubject<Void, Never>()

    @Published var host: String = UserDefaults.standard.object(forKey: SettingsKey.host.rawValue) as? String ?? "" {
        didSet {
            UserDefaults.standard.set(host, forKey: SettingsKey.host.rawValue)
            didUpdate()
        }
    }
    
    @Published var apiToken: String = UserDefaults.standard.object(forKey: SettingsKey.apiToken.rawValue) as? String ?? "" {
        didSet {
            UserDefaults.standard.set(apiToken, forKey: SettingsKey.apiToken.rawValue)
            didUpdate()
        }
    }
}

extension Settings: ObservableObject {

    private func didUpdate() {
        didChange.send()
    }
}
