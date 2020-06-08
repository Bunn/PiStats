//
//  PiHoleControlle.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

class PiholeListProvider: ObservableObject {
    @Published var piholes = Pihole.restoreAll()
    
    func saveNewPiHole(address: String, token: String) {        
        Pihole(address: address, apiToken: token).save()
    }
    
    func remove(_ pihole: Pihole) {
        if let index = piholes.firstIndex(of: pihole) {
            piholes.remove(at: index)
        }
        pihole.delete()
    }
    
    func updateData() {
        piholes = Pihole.restoreAll()
    }
}
