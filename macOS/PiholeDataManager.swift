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
    private var isUpdating = false
    private var cancellables = Set<AnyCancellable>()

    private let alertEngine = AlertEngine(rules: AlertEngine.defaultRules,
                                          notifier: LocalNotificationDispatcher(),
                                          settings: AlertSettingsStore.load())
    private lazy var monitoringScheduler = MacMonitoringScheduler(engine: alertEngine) { [weak self] in
        self?.currentSnapshots() ?? []
    }
    
    /// Computed overall status for menu bar icon
    var overallStatus: PiholeStatus {
        guard let listUpdater = listUpdater, !listUpdater.dataUpdaters.isEmpty else {
            return .unknown
        }
        
        let statuses = listUpdater.dataUpdaters.map { $0.summary.status }
        let hasErrors = listUpdater.dataUpdaters.contains { $0.summary.hasPiholeError }
        
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
        NotificationActionHandler.shared.registerCategories()
    }
    
    private func setupListUpdaterObservation() {
        cancellables.removeAll()

        guard let listUpdater = listUpdater else { return }

        listUpdater.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
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
        guard !isUpdating else { return }
        isUpdating = true
        listUpdater?.startUpdating()
        monitoringScheduler.start()
    }

    func stopUpdating() {
        guard isUpdating else { return }
        isUpdating = false
        listUpdater?.stopUpdating()
        monitoringScheduler.stop()
    }

    func refreshData() {
        let storedPiholes = DefaultPiholeStorage().restoreAllPiholes()
        guard !storedPiholes.isEmpty else {
            listUpdater?.stopUpdating()
            listUpdater = nil
            return
        }

        guard let listUpdater else {
            let updater = PiholeListUpdater(storedPiholes)
            self.listUpdater = updater
            if isUpdating {
                updater.startUpdating()
            }
            return
        }

        let storedIDs = Set(storedPiholes.map(\.uuid))
        for updater in listUpdater.dataUpdaters where !storedIDs.contains(updater.pihole.uuid) {
            listUpdater.removePihole(updater.pihole)
        }

        for pihole in storedPiholes {
            if let existing = listUpdater.dataUpdaters.first(where: { $0.pihole.uuid == pihole.uuid }) {
                if existing.pihole != pihole {
                    listUpdater.updatePihole(pihole)
                }
            } else {
                listUpdater.addPihole(pihole)
            }
        }
    }

    func handlePiholeChange(_ pihole: Pihole, isDelete: Bool) {
        if isDelete {
            listUpdater?.removePihole(pihole)
            if listUpdater?.dataUpdaters.isEmpty == true {
                listUpdater = nil
            }
            return
        }

        guard let listUpdater else {
            let updater = PiholeListUpdater([pihole])
            self.listUpdater = updater
            if isUpdating {
                updater.startUpdating()
            }
            return
        }

        if let existing = listUpdater.dataUpdaters.first(where: { $0.pihole.uuid == pihole.uuid }) {
            if existing.pihole != pihole {
                listUpdater.updatePihole(pihole)
            }
        } else {
            listUpdater.addPihole(pihole)
        }
    }

    private func currentSnapshots() -> [PiholeSnapshot] {
        guard let updaters = listUpdater?.dataUpdaters else { return [] }
        return updaters.map {
            PiholeSnapshot(piholeID: $0.pihole.uuid,
                           piholeName: $0.pihole.name,
                           reachable: !$0.summary.hasPiholeError,
                           status: $0.summary.status,
                           health: $0.summary.health)
        }
    }
}
