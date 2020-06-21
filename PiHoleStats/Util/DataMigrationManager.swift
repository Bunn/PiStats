//
//  DataMigrationManager.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 21/06/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import os.log

struct DataMigrationManager {
    private let log = Logger().osLog(describing: DataMigrationManager.self)
    
    private let oldSettingsKeyHostToken = "SettingsKeyHost"
    private var oldPiholeHost: String? {
        guard let oldPiHoleHost = UserDefaults.standard.object(forKey: oldSettingsKeyHostToken) as? String else {
            return nil
        }
        if oldPiHoleHost.isEmpty {
            return nil
        }
        return oldPiHoleHost
    }
    
    func migrateIfNecessary() {
        if hasDataStoredInSinglePiholeFormat() {
            os_log("old pi-hole setup found, starting migration...", log: self.log, type: .debug)
            migrateFromSinglePiholeToMultiples()
        }
    }
    
    private func hasDataStoredInSinglePiholeFormat() -> Bool {
        return oldPiholeHost != nil
    }
    
    private func migrateFromSinglePiholeToMultiples() {
        guard let oldPiHoleHost = oldPiholeHost else { return }
        os_log("migrating old host %@", log: self.log, type: .debug, oldPiHoleHost)
        let pihole = Pihole(address: oldPiHoleHost)
        let passwordItem = KeychainPasswordItem(service: "PiHoleStatsService", account: "PiHoleStatsAccount", accessGroup: nil)
        if let token = try? passwordItem.readPassword() {
            pihole.apiToken = token
        }
        
        try? passwordItem.deleteItem()
        UserDefaults.standard.removeObject(forKey: oldSettingsKeyHostToken)
        pihole.save()
    }
}
