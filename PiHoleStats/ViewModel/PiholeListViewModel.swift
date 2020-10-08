//
//  PiholeListViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 09/06/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation

class PiholeListViewModel: ObservableObject {
    private let piholeDataProvider: PiholeDataProvider
    var piholes: [Pihole] {
        piholeDataProvider.piholes
    }
    
    init(piholeDataProvider: PiholeDataProvider) {
         self.piholeDataProvider = piholeDataProvider
     }
    
    func addStubPihole() -> Pihole {
        let pihole = Pihole(address: "127.0.0.1")
        piholeDataProvider.add(pihole)
        return pihole
    }
    
    func remove(_ pihole: Pihole) {
        piholeDataProvider.remove(pihole)
        pihole.delete()
    }
    
    func itemViewModel(_ pihole: Pihole) -> PiholeViewModel {
        let model = PiholeViewModel(piHole: pihole)
        model.delegate = self
        return model
    }
}

extension PiholeListViewModel: PiholeViewModelDelegate {
    func piholeViewModelDidSave(_ piholeViewModel: PiholeViewModel, address: String, token: String, secure: Bool) {
            objectWillChange.send()
            if let index = piholeDataProvider.piholes.firstIndex(where: {$0.id == piholeViewModel.piHole.id}) {
                piholeDataProvider.piholes[index].address = address
                piholeDataProvider.piholes[index].apiToken = token
                piholeDataProvider.piholes[index].secure = secure
                piholeDataProvider.piholes[index].save()
            }
    }
}
