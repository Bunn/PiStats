//
//  SettingsViewModel.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//


import SwiftUI
import Combine
import Foundation

struct DisableTime: Identifiable, Codable, Hashable {
    let id = UUID()
    let seconds: Int
    
    init(seconds: Int) {
        self.seconds = seconds
    }
    
    var displayName: String {
        let duration: Duration = .seconds(seconds)
        return duration.formatted(.units(width: .wide))
    }
    
    static let defaultTimes: [DisableTime] = [
        DisableTime(seconds: 30),
        DisableTime(seconds: 60),
        DisableTime(seconds: 300),
        DisableTime(seconds: 600),
        DisableTime(seconds: 1800),
        DisableTime(seconds: 3600)
    ]
}

protocol UserDefaultsProtocol {
    func bool(forKey defaultName: String) -> Bool
    func integer(forKey defaultName: String) -> Int
    func set(_ value: Bool, forKey defaultName: String)
    func set(_ value: Int, forKey defaultName: String)
}

extension UserDefaults: UserDefaultsProtocol {}

class SettingsViewModel: ObservableObject {
    @Published var displayStatsAsList: Bool {
        didSet {
            userDefaults.set(displayStatsAsList, forKey: Keys.displayStatsAsList)
        }
    }
    
    @Published var displayAllPiholes: Bool {
        didSet {
            userDefaults.set(displayAllPiholes, forKey: Keys.displayAllPiholes)
        }
    }
    
    @Published var disablePermanently: Bool {
        didSet {
            userDefaults.set(disablePermanently, forKey: Keys.disablePermanently)
        }
    }
    
    @Published var temperatureScale: TemperatureScale {
        didSet {
            userDefaults.set(temperatureScale.rawValue, forKey: Keys.temperatureScale)
        }
    }
    
    @Published var customDisableTimes: [DisableTime] = [] {
        didSet {
            saveCustomDisableTimes()
        }
    }
    
    private let userDefaults: UserDefaultsProtocol
    
    private enum Keys {
        static let displayStatsAsList = "displayStatsAsList"
        static let displayAllPiholes = "displayAllPiholes"
        static let disablePermanently = "disablePermanently"
        static let temperatureScale = "temperatureScale"
        static let customDisableTimes = "customDisableTimes"
    }

    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.userDefaults = userDefaults
        
        // Load values from UserDefaults, with defaults if not set
        self.displayStatsAsList = userDefaults.bool(forKey: Keys.displayStatsAsList)
        self.displayAllPiholes = userDefaults.bool(forKey: Keys.displayAllPiholes)
        
        // For disablePermanently, we want true as default, but bool(forKey:) returns false if not set
        // So we need to check if the key exists first
        if (userDefaults as? UserDefaults)?.object(forKey: Keys.disablePermanently) == nil {
            self.disablePermanently = true
            userDefaults.set(true, forKey: Keys.disablePermanently)
        } else {
            self.disablePermanently = userDefaults.bool(forKey: Keys.disablePermanently)
        }
        
        // For temperatureScale, use device's locale as default if never set
        if (userDefaults as? UserDefaults)?.object(forKey: Keys.temperatureScale) == nil {
            let defaultScale: TemperatureScale = Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
            self.temperatureScale = defaultScale
            userDefaults.set(defaultScale.rawValue, forKey: Keys.temperatureScale)
        } else {
            let rawValue = userDefaults.integer(forKey: Keys.temperatureScale)
            self.temperatureScale = TemperatureScale(rawValue: rawValue) ?? .celsius
        }
        
        // Load custom disable times
        self.customDisableTimes = loadCustomDisableTimes()
    }
    
    private func loadCustomDisableTimes() -> [DisableTime] {
        guard let data = (userDefaults as? UserDefaults)?.data(forKey: Keys.customDisableTimes),
              let times = try? JSONDecoder().decode([DisableTime].self, from: data) else {
            return DisableTime.defaultTimes
        }
        return times
    }
    
    private func saveCustomDisableTimes() {
        guard let data = try? JSONEncoder().encode(customDisableTimes) else { return }
        (userDefaults as? UserDefaults)?.set(data, forKey: Keys.customDisableTimes)
    }
    
    func addCustomDisableTime(_ disableTime: DisableTime) {
        if !customDisableTimes.contains(where: { $0.seconds == disableTime.seconds }) {
            customDisableTimes.append(disableTime)
        }
    }
    
    func removeCustomDisableTime(_ disableTime: DisableTime) {
        customDisableTimes.removeAll { $0.id == disableTime.id }
    }
    
    func resetToDefaultDisableTimes() {
        customDisableTimes = DisableTime.defaultTimes
    }
}
