import SwiftUI
import WidgetKit
import PiStatsCore

// MARK: - Widget Background Extension

extension View {
    func widgetBackground<V>(@ViewBuilder content: () -> V) -> some View where V : View {
        if #available(iOS 17.0, *) {
            return containerBackground(for: .widget) {
                content()
            }
        } else {
            return background(content())
        }
    }
}

// MARK: - Widget Constants

/// Widget-specific constants that mirror the main app's AppConstants
public struct AppColors {
    public static let domainsOnBlocklist = Color("DomainsOnBlockList")
    public static let totalQueries = Color("TotalQueries")
    public static let queriesBlocked = Color("QueriesBlocked")
    public static let percentBlocked = Color("PercentBlocked")
    public static let statusOffline = Color("StatusOffline")
    public static let statusOnline = Color("StatusOnline")
    public static let statusWarning = Color("StatusWarning")
}

public struct SystemImages {
    public static let piholeSetupMonitor = "binoculars"
    public static let metricTemperature = "thermometer"
    public static let metricUptime = "power"
    public static let metricLoadAverage = "cpu"
    public static let metricMemoryUsage = "memorychip"
    public static let domainsOnBlockList = "list.bullet"
    public static let totalQueries = "globe"
    public static let queriesBlocked = "hand.raised"
    public static let percentBlocked = "chart.pie"
}

// MARK: - Legacy UIConstants (for backward compatibility)
/// Deprecated: Use AppColors and SystemImages directly
public struct UIConstants {
    public struct Colors {
        public static let domainsOnBlocklist = AppColors.domainsOnBlocklist
        public static let totalQueries = AppColors.totalQueries
        public static let queriesBlocked = AppColors.queriesBlocked
        public static let percentBlocked = AppColors.percentBlocked
        public static let statusOffline = AppColors.statusOffline
        public static let statusOnline = AppColors.statusOnline
        public static let statusWarning = AppColors.statusWarning
    }
    
    public struct SystemImages {
        public static let piholeSetupMonitor = "binoculars"
        public static let metricTemperature = "thermometer"
        public static let metricUptime = "power"
        public static let metricLoadAverage = "cpu"
        public static let metricMemoryUsage = "memorychip"
        public static let domainsOnBlockList = "list.bullet"
        public static let totalQueries = "globe"
        public static let queriesBlocked = "hand.raised"
        public static let percentBlocked = "chart.pie"
    }
}

// MARK: - Shared Storage Access

/// Widget-specific storage implementation that uses the shared app group
final class WidgetPiholeStorage: PiholeStorage {
    private let storage = DefaultPiholeStorage()
    
    func savePihole(_ pihole: Pihole) {
        storage.savePihole(pihole)
    }
    
    func deletePihole(_ pihole: Pihole) {
        storage.deletePihole(pihole)
    }
    
    func deleteAllPiholes() {
        storage.deleteAllPiholes()
    }
    
    func restorePihole(_ id: UUID) -> Pihole? {
        return storage.restorePihole(id)
    }
    
    func restoreAllPiholes() -> [Pihole] {
        return storage.restoreAllPiholes()
    }
}

/// Global storage instance for widget usage
let widgetStorage = WidgetPiholeStorage() 