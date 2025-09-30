//
//  PiholeListUpdating.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import Combine
import Foundation
import PiStatsCore

protocol PiholeListUpdating {
    func startUpdating()
    func stopUpdating()
    func addPihole(_ pihole: Pihole)
    func removePihole(_ pihole: Pihole)
}

final class PiholeListUpdater: PiholeListUpdating, ObservableObject {
    @Published private(set) var dataUpdaters: [PiholeSummaryDataUpdater]
    private var cancellables = Set<AnyCancellable>()

    init(_ piholes: [Pihole]) {
        self.dataUpdaters = piholes.map { .init(pihole: $0) }
        setupObservers()
    }
    
    private func setupObservers() {
        // Clear existing cancellables first
        cancellables.removeAll()
        
        // Subscribe to changes from all data updaters and their summaries
        for updater in dataUpdaters {
            updater.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
            
            updater.summary.objectWillChange
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &cancellables)
        }
    }

    func startUpdating() {
        dataUpdaters.forEach { updater in
            updater.startUpdating()
        }
    }

    func stopUpdating() {
        dataUpdaters.forEach { updater in
            updater.stopUpdating()
        }
    }
    
    func addPihole(_ pihole: Pihole) {
        let newUpdater = PiholeSummaryDataUpdater(pihole: pihole)
        dataUpdaters.append(newUpdater)
        setupObservers()
        newUpdater.startUpdating()
    }
    
    func removePihole(_ pihole: Pihole) {
        if let index = dataUpdaters.firstIndex(where: { $0.pihole.uuid == pihole.uuid }) {
            let updater = dataUpdaters[index]
            updater.stopUpdating()
            dataUpdaters.remove(at: index)
            setupObservers()
        }
    }
    
    func updatePihole(_ pihole: Pihole) {
        if let index = dataUpdaters.firstIndex(where: { $0.pihole.uuid == pihole.uuid }) {
            let oldUpdater = dataUpdaters[index]
            oldUpdater.stopUpdating()
            
            let newUpdater = PiholeSummaryDataUpdater(pihole: pihole)
            dataUpdaters[index] = newUpdater
            setupObservers()
            newUpdater.startUpdating()
        }
    }
}
