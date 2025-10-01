//
//  SettingsStore.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//

import SwiftUI
import Combine

final class SettingsStore: ObservableObject {
    @Published var displayStatsAsList: Bool
    @Published var displayAllPiholes: Bool
    @Published var disablePermanently: Bool
    @Published var temperatureScale: TemperatureScale
    @Published var customDisableTimes: [DisableTime]
    
    private let viewModel: SettingsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(userDefaults: UserDefaultsProtocol = UserDefaults.standard) {
        self.viewModel = SettingsViewModel(userDefaults: userDefaults)
        
        // Initialize published properties with current values
        self.displayStatsAsList = viewModel.displayStatsAsList
        self.displayAllPiholes = viewModel.displayAllPiholes
        self.disablePermanently = viewModel.disablePermanently
        self.temperatureScale = viewModel.temperatureScale
        self.customDisableTimes = viewModel.customDisableTimes
        
        // Bind to view model updates
        setupBindings()
    }
    
    var settingsViewModel: SettingsViewModel {
        return viewModel
    }
    
    private func setupBindings() {
        viewModel.$displayStatsAsList
            .sink { [weak self] value in
                self?.displayStatsAsList = value
            }
            .store(in: &cancellables)
        
        viewModel.$displayAllPiholes
            .sink { [weak self] value in
                self?.displayAllPiholes = value
            }
            .store(in: &cancellables)
        
        viewModel.$disablePermanently
            .sink { [weak self] value in
                self?.disablePermanently = value
            }
            .store(in: &cancellables)
        
        viewModel.$temperatureScale
            .sink { [weak self] value in
                self?.temperatureScale = value
            }
            .store(in: &cancellables)
        
        viewModel.$customDisableTimes
            .sink { [weak self] value in
                self?.customDisableTimes = value
            }
            .store(in: &cancellables)
    }
} 
