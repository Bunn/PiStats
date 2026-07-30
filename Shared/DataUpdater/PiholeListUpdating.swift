//
//  PiholeListUpdating.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import Combine
import Foundation
import PiStatsCore

@MainActor
protocol PiholeListUpdating {
    func startUpdating()
    func stopUpdating()
    func addPihole(_ pihole: Pihole)
    func removePihole(_ pihole: Pihole)
}

@MainActor
final class PiholeListUpdater: PiholeListUpdating, ObservableObject {
    @Published private(set) var dataUpdaters: [PiholeSummaryDataUpdater]
    private var cancellables = Set<AnyCancellable>()
    private(set) var isUpdating = false

    init(_ piholes: [Pihole]) {
        self.dataUpdaters = piholes.map { .init(pihole: $0) }
        setupObservers()
    }

    init(dataUpdaters: [PiholeSummaryDataUpdater]) {
        self.dataUpdaters = dataUpdaters
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
        guard !isUpdating else { return }
        isUpdating = true
        dataUpdaters.forEach { updater in
            updater.startUpdating()
        }
    }

    func stopUpdating() {
        guard isUpdating else { return }
        isUpdating = false
        dataUpdaters.forEach { updater in
            updater.stopUpdating()
        }
    }
    
    func addPihole(_ pihole: Pihole) {
        let newUpdater = PiholeSummaryDataUpdater(pihole: pihole)
        dataUpdaters.append(newUpdater)
        setupObservers()
        if isUpdating {
            newUpdater.startUpdating()
        }
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
            guard oldUpdater.pihole != pihole else { return }

            let retainedSummary = PiholeSummaryData(
                copying: oldUpdater.summary,
                name: pihole.name
            )
            oldUpdater.stopUpdating()

            let newUpdater = PiholeSummaryDataUpdater(
                pihole: pihole,
                initialSummary: retainedSummary
            )
            dataUpdaters[index] = newUpdater
            setupObservers()
            if isUpdating {
                newUpdater.startUpdating()
            }
        }
    }

    func addDomains(
        _ domains: [DomainRule],
        from currentUpdater: PiholeSummaryDataUpdater,
        scope: PiholeConfigurationChangeScope
    ) async throws {
        try await applyConfigurationChange(from: currentUpdater, scope: scope) {
            try await $0.addDomains(domains)
        }
    }

    func removeDomains(
        _ domains: [DomainRule],
        from currentUpdater: PiholeSummaryDataUpdater,
        scope: PiholeConfigurationChangeScope
    ) async throws {
        try await applyConfigurationChange(from: currentUpdater, scope: scope) {
            try await $0.removeDomains(domains)
        }
    }

    func setDomain(
        _ domain: DomainRule,
        enabled: Bool,
        from currentUpdater: PiholeSummaryDataUpdater,
        scope: PiholeConfigurationChangeScope
    ) async throws {
        try await applyConfigurationChange(from: currentUpdater, scope: scope) {
            try await $0.setDomain(domain, enabled: enabled)
        }
    }

    func setAdlist(
        _ adlist: AdList,
        enabled: Bool,
        from currentUpdater: PiholeSummaryDataUpdater,
        scope: PiholeConfigurationChangeScope
    ) async throws {
        try await applyConfigurationChange(from: currentUpdater, scope: scope) {
            try await $0.setAdlist(adlist, enabled: enabled)
        }
    }

    private func applyConfigurationChange(
        from currentUpdater: PiholeSummaryDataUpdater,
        scope: PiholeConfigurationChangeScope,
        change: (PiholeSummaryDataUpdater) async throws -> Void
    ) async throws {
        try await change(currentUpdater)

        guard scope == .allPiholes else { return }

        var failures: [PiholeConfigurationSyncError.Failure] = []
        for updater in dataUpdaters where updater.pihole.uuid != currentUpdater.pihole.uuid {
            do {
                try await change(updater)
            } catch {
                failures.append(
                    .init(
                        piholeName: updater.pihole.name,
                        errorDescription: error.localizedDescription
                    )
                )
            }
        }

        guard failures.isEmpty else {
            throw PiholeConfigurationSyncError(
                currentPiholeName: currentUpdater.pihole.name,
                failures: failures
            )
        }
    }
}
