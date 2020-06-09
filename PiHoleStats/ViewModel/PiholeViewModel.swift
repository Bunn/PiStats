//
//  PiHoleViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 31/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftUI

protocol PiholeViewModelDelegate: AnyObject {
    func piholeViewModelDidSave(_ piholeViewModel: PiholeViewModel, address: String, token: String)
}

class PiholeViewModel: ObservableObject {
    @Published var address: String
    @Published var token: String
    weak var delegate: PiholeViewModelDelegate?
    let piHole: Pihole
    
    internal init(piHole: Pihole) {
        self.piHole = piHole
        self.address = piHole.address
        self.token = piHole.apiToken
    }
    
    func save() {
        delegate?.piholeViewModelDidSave(self, address: address, token: token)
    }
}
