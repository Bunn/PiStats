//
//  PiHoleViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 31/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftUI

class PiholeViewModel: ObservableObject {
    @Published var address: String
    @Published var token: String
    var piHole: Pihole
    
    internal init(piHole: Pihole) {
        self.piHole = piHole
        self.address = piHole.address
        self.token = piHole.apiToken
    }
    
    func save() {
        piHole.address = address
        piHole.apiToken = token
        piHole.save()
    }
}
