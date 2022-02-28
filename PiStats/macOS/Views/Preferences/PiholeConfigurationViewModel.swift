//
//  PiholeConfigurationViewModel.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 28/02/2022.
//

import Foundation
import PiStatsCore

final class PiholeConfigurationViewModel: ObservableObject {
    let pihole: Pihole
    
    @Published var name: String {
        didSet {
            pihole.displayName = name
        }
    }
    @Published var host: String
    
    internal init(pihole: Pihole) {
        self.pihole = pihole
        print("Tes1t")
        self.name = pihole.displayName ?? ""
        self.host = pihole.address
        
    }
}

extension PiholeConfigurationViewModel: Previewable {
    public static func preview() -> PiholeConfigurationViewModel {
        return PiholeConfigurationViewModel(pihole: Pihole.preview())
    }
}
