import Foundation
import Combine
import ServiceManagement

final class MacPreferences: ObservableObject {
    var temperatureScale: TemperatureScale = .celsius {
        didSet {
            saveTemperatureScale()
        }
    }
    var startAtLogin: Bool = false {
        didSet {
            saveStartAtLogin()
        }
    }
    var disablePermanently: Bool = true {
        didSet {
            saveDisablePermanently()
        }
    }

    private let defaults: UserDefaults
    init(defaults: UserDefaults = UserDefaults.shared()) {
        self.defaults = defaults
        self.temperatureScale = Self.loadTemperatureScale(from: defaults)
        self.startAtLogin = Self.loadStartAtLoginValue(from: defaults)
        self.disablePermanently = Self.loadBoolValue(
            from: defaults,
            key: PreferencesConstants.Keys.disablePermanently,
            defaultValue: true
        )
    }

    func saveTemperatureScale() {
        defaults.set(temperatureScale.rawValue, forKey: PreferencesConstants.Keys.temperatureScale)
    }
    
    func saveStartAtLogin() {
        defaults.set(startAtLogin, forKey: PreferencesConstants.Keys.startAtLogin)
        updateLoginItem()
    }
    
    func saveDisablePermanently() {
        defaults.set(disablePermanently, forKey: PreferencesConstants.Keys.disablePermanently)
    }

    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if startAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }
}

// MARK: - Private Helpers
private extension MacPreferences {
    static func loadBoolValue(from defaults: UserDefaults, key: String, defaultValue: Bool) -> Bool {
        if defaults.object(forKey: key) == nil {
            defaults.set(defaultValue, forKey: key)
            return defaultValue
        }
        return defaults.bool(forKey: key)
    }
    
    static func loadTemperatureScale(from defaults: UserDefaults) -> TemperatureScale {
        if defaults.object(forKey: PreferencesConstants.Keys.temperatureScale) == nil {
            let defaultScale: TemperatureScale = Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
            defaults.set(defaultScale.rawValue, forKey: PreferencesConstants.Keys.temperatureScale)
            return defaultScale
        } else {
            let rawValue = defaults.integer(forKey: PreferencesConstants.Keys.temperatureScale)
            return TemperatureScale(rawValue: rawValue) ?? .celsius
        }
    }
    
    static func loadStartAtLoginValue(from defaults: UserDefaults) -> Bool {
        // Check if we have a stored preference
        if defaults.object(forKey: PreferencesConstants.Keys.startAtLogin) != nil {
            return defaults.bool(forKey: PreferencesConstants.Keys.startAtLogin)
        }
        
        // Check actual login item status for initial value
        if #available(macOS 13.0, *) {
            let isRegistered = SMAppService.mainApp.status == .enabled
            defaults.set(isRegistered, forKey: PreferencesConstants.Keys.startAtLogin)
            return isRegistered
        }
        
        // Default to false for older macOS versions
        defaults.set(false, forKey: PreferencesConstants.Keys.startAtLogin)
        return false
    }
}

