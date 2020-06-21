//
//  DataMigrationManager.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 21/06/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

struct DataMigrationManager {
    
    func migrateIfNecessary() {
        if hasDataStoredInSinglePiholeFormat() {
            
        }
    }
    
    private func hasDataStoredInSinglePiholeFormat() -> Bool {
        return false
    }
}
