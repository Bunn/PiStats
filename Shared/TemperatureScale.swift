//
//  TemperatureScale.swift
//  PiStats
//
//  Created by Fernando Bunn on 21/09/2025.
//


enum TemperatureScale: Int, CaseIterable {
    case celsius = 0
    case fahrenheit = 1
    
    var displayName: String {
        switch self {
        case .celsius:
            return UserText.Settings.temperatureScaleCelsius
        case .fahrenheit:
            return UserText.Settings.temperatureScaleFahrenheit
        }
    }
}