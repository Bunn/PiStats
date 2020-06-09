//
//  piholeservice.swift
//  piholestats
//
//  Created by Fernando Bunn on 24/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftHole
import SwiftUI

class PiholeDataProvider: ObservableObject {
    enum PiholeStatus {
        case allEnabled
        case allDisabled
        case enabledAndDisabled
    }
    
    private let pollingTimeInterval: TimeInterval = 3
    private var timer: Timer?
    @Published private(set) var totalQueries = ""
    @Published private(set) var queriesBlocked = ""
    @Published private(set) var percentBlocked = ""
    @Published private(set) var domainsOnBlocklist = ""
    @Published private(set) var errorMessage = ""
    @Published private(set) var status: PiholeStatus = .allDisabled
    
    var canDisplayEnableDisableButton: Bool {
        return piholes.allSatisfy { $0.apiToken.isEmpty == false }
    }
    
    var changeStatusButtonTitle: String {
        if status != .allDisabled {
            return UIConstants.Strings.buttonDisable
        } else {
            return UIConstants.Strings.buttonEnable
        }
    }
    
    var statusColor: Color {
        switch status {
        case .allDisabled:
            return UIConstants.Colors.disabled
        case .allEnabled:
            return UIConstants.Colors.enabled
        case .enabledAndDisabled:
            return UIConstants.Colors.enabledAndDisabled
        }
    }
    
    var statusText: String {
          switch status {
          case .allDisabled:
            return UIConstants.Strings.statusDisabled
          case .allEnabled:
            return UIConstants.Strings.statusEnabled
          case .enabledAndDisabled:
              return UIConstants.Strings.statusEnabledAndDisabled
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
    
    var piholes: [Pihole]
    
    init(piholes: [Pihole]) {
        self.piholes = piholes
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
        piholes.forEach {
            $0.disablePiHole(seconds: seconds) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.updateStatus()
                    case .failure(let error):
                        self.handleError(error)
                    }
                }
            }
        }
    }
    
    func enablePiHole() {
        piholes.forEach {
            $0.enablePiHole { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self.updateStatus()
                    case .failure(let error):
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
        piholes.forEach { pihole in
            pihole.updateSummary { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.updateData()
                    }
                }
            }
        }
    }
    
    private func updateData() {
        let sumDNSQueries = piholes.compactMap { $0.summary }.reduce(0) { value, pihole in value + pihole.dnsQueriesToday }
        totalQueries = numberFormatter.string(from: NSNumber(value: sumDNSQueries)) ?? "-"
        
        let sumQueriesBlocked = piholes.compactMap { $0.summary }.reduce(0) { value, pihole in value + pihole.adsBlockedToday }
        queriesBlocked = numberFormatter.string(from: NSNumber(value: sumQueriesBlocked)) ?? "-"
        
        let sumDomainOnBlocklist = piholes.compactMap { $0.summary }.reduce(0) { value, pihole in value + pihole.domainsBeingBlocked }
        domainsOnBlocklist = numberFormatter.string(from: NSNumber(value: sumDomainOnBlocklist)) ?? "-"
        
        let percentage = Double(sumQueriesBlocked) / Double(sumDNSQueries)
        percentBlocked = percentageFormatter.string(from: NSNumber(value: percentage)) ?? "-"
        errorMessage = ""
        
        updateStatus()
    }
    
    private func updateStatus() {
        let allStatus = Set(piholes.map { $0.active })
        if allStatus.count > 1 {
            status = .enabledAndDisabled
        } else if allStatus.randomElement() == false {
            status = .allDisabled
        } else {
            status = .allEnabled
        }
    }
}
