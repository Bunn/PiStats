//
//  UserPreferences.swift
//  PiStats
//
//  Created by Fernando Bunn on 23/06/2025.
//

import Foundation

class UserPreferences {
    private static let didMigrateAppGroupKey = "didMigrateAppGroup"
    
    var didMigrateAppGroup: Bool {
        get {
            UserDefaults.shared().bool(forKey: Self.didMigrateAppGroupKey)
        }
        set {
            UserDefaults.shared().set(newValue, forKey: Self.didMigrateAppGroupKey)
        }
    }
} 