//
//  PiHoleViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 31/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftUI

enum SecureTag: Int {
    case unsecure
    case secure
}

protocol PiholeViewModelDelegate: AnyObject {
    func piholeViewModelDidSave(_ piholeViewModel: PiholeViewModel, address: String, token: String, secure: Bool, reverserproxy: Bool)
}

class PiholeViewModel: ObservableObject {
    @Published var address: String
    @Published var token: String
    @Published var secure: Bool
    @Published var reverserproxy: Bool
    @Published var secureTag: SecureTag {
        didSet {
            secure = secureTag == SecureTag.secure
        }
    }

    weak var delegate: PiholeViewModelDelegate?
    let piHole: Pihole
    
    var json: String {
        return """
        {
            "pihole": {
                "host": "\(piHole.address)",
                "port": \(piHole.port ?? 80),
                "token": "\(piHole.apiToken)",
                "secure": \(piHole.secure)
                "reverserproxy": \(piHole.reverserproxy)
            }
        }
        """
    }
    
    internal init(piHole: Pihole) {
        self.piHole = piHole
        self.address = piHole.address
        self.token = piHole.apiToken
        self.secure = piHole.secure
        self.reverserproxy = piHole.reverserproxy
        self.secureTag = piHole.secure ? SecureTag.secure : SecureTag.unsecure
    }
    
    func save() {
        delegate?.piholeViewModelDidSave(self, address: address, token: token, secure: secure, reverserproxy: reverserproxy)
    }
}
