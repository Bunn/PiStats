//
//  PiHoleControlle.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

class PiholeController: ObservableObject {
    @Published var piHoles = Pihole.restoreAll()
    
    func getCurrentPiHole() -> Pihole? {
        piHoles.first
    }
    
    func saveNewPiHole(address: String, token: String) {        
        Pihole(address: address, apiToken: token).save()
        
        Pihole.restoreAll().forEach {
            print($0.address)
        }
    }
    
    func addStubPihole() -> Pihole {
        let piHole = Pihole(address: "127.0.0.1")
        piHoles.append(piHole)
        return piHole
    }
    
    func deletePihole(_ pihole: Pihole) {
        
    }
}
