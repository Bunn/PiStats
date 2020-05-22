//
//  APIToken.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 16/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

struct APIToken {
    private static let serviceName = "PiHoleStatsService"
    private static let accountName = "PiHoleStatsAccount"
    private let passwordItem = KeychainPasswordItem(service: APIToken.serviceName, account: APIToken.accountName, accessGroup: nil)
    
    public var token: String {
        get {
            do {
                return try passwordItem.readPassword()
            }
            catch {
                return ""
            }
        }
        set {
            try? passwordItem.savePassword(newValue)
        }
    }
}
