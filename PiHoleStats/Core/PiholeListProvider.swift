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
    
    func getCurrentPiHole() -> Pihole? {
        piholes.first
    }
    
    func saveNewPiHole(address: String, token: String) {        
        Pihole(address: address, apiToken: token).save()
        
        Pihole.restoreAll().forEach {
            print($0.address)
        }
    }
    
    func addStubPihole() -> Pihole {
        let piHole = Pihole(address: "127.0.0.1")
        piholes.append(piHole)
        return piHole
    }
    
    func remove(_ pihole: Pihole) {
        if let index = piholes.firstIndex(of: pihole) {
            piholes.remove(at: index)
        }
        pihole.delete()
    }
}
