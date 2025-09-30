//
//  APIToken.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 16/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import PiStatsCore

struct APIToken {
    internal init(accountName: String) {
        self.accountName = accountName
        self.passwordItem = KeychainPasswordItem(service: APIToken.serviceName, account: accountName, accessGroup: "group.dev.bunn.PiStatsMobile")
        migratePasswordItemIfNecessary(accountName)
    }
    
    private mutating func migratePasswordItemIfNecessary(_ accountName: String) {
        guard UserPreferences().didMigrateAppGroup == false else { return }
        let oldPasswordItem = KeychainPasswordItem(service: APIToken.serviceName, account: accountName, accessGroup: nil)
        
        if let oldPassword = try? oldPasswordItem.readPassword(), oldPassword.count > 0 {
            self.token = oldPassword
            UserPreferences().didMigrateAppGroup = true
        }
    }
    
    private static let serviceName = "PiHoleStatsService"
    let accountName: String
    
    private let passwordItem: KeychainPasswordItem
    
    public var token: String {
        get {
            do {
                return try passwordItem.readPassword()
            } catch {
                return ""
            }
        }
        
        set {
            /*
             It might error out when trying to delete during development because of digital signing changing
             which shouldn't be a problem on released version
             https://forums.developer.apple.com/thread/69841
             */
            try? passwordItem.savePassword(newValue)
            if newValue.isEmpty {
                delete()
            }
        }
    }
    
    public func delete() {
        do {
            try passwordItem.deleteItem()
        } catch {
            Log.security.error("Keychain delete error: \(String(describing: error))")
        }
    }
}
