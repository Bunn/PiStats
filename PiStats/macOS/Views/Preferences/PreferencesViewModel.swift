//
//  PreferencesViewModel.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import Foundation
import PiStatsCore
import Combine

class PreferencesViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    private let piholeManager: PiholeManager
    @Published var piholes: [Pihole]
    
    init(piholeManager: PiholeManager) {
        self.piholeManager = piholeManager
        self.piholes = piholeManager.piholes
        
        self.piholeManager
            .objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.piholes = piholeManager.piholes
            }.store(in: &cancellables)
    }
    
    
    func test() {
        piholeManager.test()
    }
}
