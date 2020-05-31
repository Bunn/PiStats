//
//  PiHoleService.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 24/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine
import SwiftHole

class PiholeDataProvider: ObservableObject {
    let piHoles: [Pihole]
    private let pollingTimeInterval: TimeInterval = 3
    private var timer: Timer?

    @Published private (set) var totalQueries = ""
    @Published private (set) var queriesBlocked = ""
    @Published private (set) var percentBlocked = ""
    @Published private (set) var domainsOnBlocklist = ""
    @Published private (set) var errorMessage = ""
    @Published private (set) var changeStatusButtonTitle = ""
    @Published private (set) var status = ""
    @Published private (set) var active: Bool = false {
        didSet {
            changeStatusButtonTitle = active ? UIConstants.Strings.buttonDisable: UIConstants.Strings.buttonEnable
            status = active ? UIConstants.Strings.statusEnabled : UIConstants.Strings.statusDisabled
        }
    }
    
    private lazy var percentageFormatter: NumberFormatter = {
          let n = NumberFormatter()
          n.numberStyle = .percent
          n.minimumFractionDigits = 2
          n.maximumFractionDigits = 2
          return n
      }()
      
      private lazy var numberFormatter: NumberFormatter = {
          let n = NumberFormatter()
          n.numberStyle = .decimal
          n.maximumFractionDigits = 0
          return n
      }()
    
    init(piHoles: [Pihole]) {
        self.piHoles = piHoles
    }
    
    func startPolling() {
        self.fetchSummaryData()
        timer = Timer.scheduledTimer(withTimeInterval: pollingTimeInterval, repeats: true) { _ in
            self.fetchSummaryData()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
    }
    
    func resetErrorMessage() {
        errorMessage = ""
    }
    
    func disablePiHole(seconds: Int = 0) {
        piHoles.forEach {
            $0.disablePiHole(seconds: seconds) { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.active = false
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    func enablePiHole() {
        piHoles.forEach {
            $0.enablePiHole { result in
                switch result {
                case .success:
                    DispatchQueue.main.async {
                        self.active = true
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    private func handleError(_ error: SwiftHoleError) {
        switch error {
        case .malformedURL:
            self.errorMessage = UIConstants.Strings.Error.invalidURL
        case .invalidDecode(let decodeError):
            self.errorMessage = "\(UIConstants.Strings.Error.decodeResponseError): \(decodeError.localizedDescription)"
        case .noAPITokenProvided:
            self.errorMessage = UIConstants.Strings.Error.noAPITokenProvided
        case .sessionError(let sessionError):
            self.errorMessage = "\(UIConstants.Strings.Error.sessionError): \(sessionError.localizedDescription)"
        case .invalidResponseCode(let responseCode):
            self.errorMessage = "\(UIConstants.Strings.Error.sessionError): \(responseCode)"
        case .invalidResponse:
            self.errorMessage = UIConstants.Strings.Error.invalidResponse
        case .invalidAPIToken:
            self.errorMessage = UIConstants.Strings.Error.invalidAPIToken
        }
    }
    
    private func fetchSummaryData() {
        piHoles.forEach {
            $0.fetchSummary { result in
                switch result {
                case .success(let piholeSummary):
                    DispatchQueue.main.async {
                        self.updateData(summary: piholeSummary)
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    private func updateData(summary: Summary) {
        totalQueries = numberFormatter.string(from: NSNumber(value: summary.dnsQueriesToday)) ?? "-"
        queriesBlocked = numberFormatter.string(from: NSNumber(value: summary.adsBlockedToday)) ?? "-"
        percentBlocked = percentageFormatter.string(from: NSNumber(value: summary.adsPercentageToday / 100.0)) ?? "-"
        domainsOnBlocklist = numberFormatter.string(from: NSNumber(value: summary.domainsBeingBlocked)) ?? "-"
        active = summary.status.lowercased() == "enabled"
        errorMessage = ""
    }
}
