//
//  PiholeDataManager.swift
//  PiStats
//
//  Created by Fernando Bunn on 26/09/2025.
//

import SwiftUI
import PiStatsCore
import Combine

@MainActor
class PiholeDataManager: ObservableObject {
    @Published var listUpdater: PiholeListUpdater? {
        didSet {
            setupListUpdaterObservation()
        }
    }
    
    private var hasInitialized = false
    private var cancellables = Set<AnyCancellable>()
    
    /// Computed overall status for menu bar icon
    var overallStatus: PiholeStatus {
        guard let listUpdater = listUpdater, !listUpdater.dataUpdaters.isEmpty else {
            return .unknown
        }
        
        let statuses = listUpdater.dataUpdaters.map { $0.summary.status }
        let hasErrors = listUpdater.dataUpdaters.contains { $0.summary.hasError }
        
        if hasErrors {
            return .unknown
        }
        
        let uniqueStatuses = Set(statuses)
        if uniqueStatuses.count == 1, let singleStatus = uniqueStatuses.first {
            return singleStatus
        }
        
        return .unknown
    }
    
    /// System image name for menu bar based on overall status
    var menuBarIcon: String {
        switch overallStatus {
        case .enabled:
            return SystemImages.piholeStatusOnline
        case .disabled:
            return SystemImages.piholeStatusOffline
        case .unknown:
            return SystemImages.piholeStatusWarning
        }
    }
    
    init() {
        setupInitialData()
    }
    
    private func setupListUpdaterObservation() {
        cancellables.removeAll()
        
        guard let listUpdater = listUpdater else { return }
        
        listUpdater.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        for updater in listUpdater.dataUpdaters {
            updater.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.objectWillChange.send()
                    }
                }
                .store(in: &cancellables)
            
            updater.summary.objectWillChange
                .sink { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.objectWillChange.send()
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    private func setupInitialData() {
        guard !hasInitialized else { return }
        
        loadPiholes()
        hasInitialized = true
    }
    
    private func loadPiholes() {
        let storage = DefaultPiholeStorage()
        let piholes = storage.restoreAllPiholes()
        
        if !piholes.isEmpty {
            listUpdater = PiholeListUpdater(piholes)
        } else {
            listUpdater = nil
        }
    }
    
    func startUpdating() {
        listUpdater?.startUpdating()
    }
    
    func stopUpdating() {
        listUpdater?.stopUpdating()
    }
    
    func refreshData() {
        listUpdater?.stopUpdating()
        loadPiholes()
        listUpdater?.startUpdating()
    }
}
