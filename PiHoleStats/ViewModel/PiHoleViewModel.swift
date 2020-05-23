//
//  PiHoleViewModel.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 11/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import Combine
import SwiftHole

class PiHoleViewModel: ObservableObject {
    let pollingTimeInterval: TimeInterval = 3
    @Published private (set) var totalQueries: String = ""
    @Published private (set) var queriesBlocked: String = ""
    @Published private (set) var percentBlocked: String = ""
    @Published private (set) var domainsOnBlocklist: String = ""
    @Published private (set) var errorMessage: String = ""
    @Published private (set) var active: Bool = false {
        didSet {
            changeStatusButtonTitle = active ? UIConstants.Strings.buttonDisable: UIConstants.Strings.buttonEnable
            status = active ? UIConstants.Strings.statusEnabled : UIConstants.Strings.statusDisabled
        }
    }
    @Published private (set) var changeStatusButtonTitle: String = ""
    @Published private (set) var status: String = ""

    var isSettingsEmpty: Bool {
        preferences.host.isEmpty
    }
    
    private var timer: Timer?
    private let preferences: Preferences
    
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
    
    init(preferences: Preferences) {
        self.preferences = preferences
    }
    
    func startPolling() {
        self.fetchSummaryData()
        timer = Timer.scheduledTimer(withTimeInterval: pollingTimeInterval, repeats: true) { timer in
            self.fetchSummaryData()
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
    }
    
    func resetErrorMessage() {
        errorMessage = ""
    }
    
    func disablePiHole() {
        SwiftHole(host: preferences.host, port: preferences.port, apiToken: preferences.apiToken).disablePiHole() { result in
            switch result {
            case .success():
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
    
    func enablePiHole() {
        SwiftHole(host: preferences.host, port: preferences.port, apiToken: preferences.apiToken).enablePiHole() { result in
            switch result {
            case .success():
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
        if isSettingsEmpty {
            errorMessage = UIConstants.Strings.openSettingsToConfigureHost
            return
        }
        
        SwiftHole(host: preferences.host, port: preferences.port, apiToken: preferences.apiToken).fetchSummary{ result in
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
    
    private func updateData(summary: Summary) {
        totalQueries = numberFormatter.string(from:  NSNumber(value: summary.dnsQueriesToday)) ?? "-"
        queriesBlocked = numberFormatter.string(from:  NSNumber(value: summary.adsBlockedToday)) ?? "-"
        percentBlocked = percentageFormatter.string(from:  NSNumber(value: summary.adsPercentageToday / 100.0)) ?? "-"
        domainsOnBlocklist = numberFormatter.string(from:  NSNumber(value: summary.domainsBeingBlocked)) ?? "-"
        active = summary.status.lowercased() == "enabled"
        errorMessage = ""
    }
}
