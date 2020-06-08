//
//  PiholeListViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 08/06/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

class PiholeListViewModel: ObservableObject {
    let piholeListProvider: PiholeListProvider
    var piholes: [Pihole]
    
    init(piholeListProvider: PiholeListProvider) {
        self.piholeListProvider = piholeListProvider
        self.piholes = self.piholeListProvider.piholes
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
        piholeListProvider.remove(pihole)
    }
}
