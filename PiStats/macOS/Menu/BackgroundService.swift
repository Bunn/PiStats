//
//  BackgroundService.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/07/2021.
//

import Foundation
import PiStatsCore
import Combine
import os.log

class BackgroundService: ObservableObject {
    private let log = OSLog(subsystem: "BackgroundService", category: String(describing: BackgroundService.self))

    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var status: PiholeStatus = PiholeStatus.allDisabled
    private var dataProvider: SummaryDataProvider?

    var piholes: [Pihole]? {
        didSet {
            setupCancellables()
            setupData()
        }
    }

    private func setupCancellables() {
        guard let piholes = piholes else { return }
        Publishers.MergeMany(piholes.map { $0.$enabled })
            .receive(on: DispatchQueue.main)
            .sink { _ in
            self.updateStatus()
        }.store(in: &cancellables)
    }
    
    private func updateStatus() {
        guard let piholes = piholes else { return }
        let allStatus = Set(piholes.map { $0.enabled })
        if allStatus.count > 1 {
            status = .enabledAndDisabled
        } else if allStatus.randomElement() == false {
            status = .allDisabled
        } else {
            status = .allEnabled
        }
    }
    
    private func setupData() {
        guard let piholes = piholes else { return }
        dataProvider = SummaryDataProvider(piholes: piholes, customPolling: 10)
    }
    
    func startPolling() {
        os_log("Starting background polling")
        dataProvider?.startPolling()
    }
    
    func stopPolling() {
        os_log("Stopping background polling")
        dataProvider?.startPolling()
    }
}
