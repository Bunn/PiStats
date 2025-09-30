import Foundation
import OSLog

public enum LogCategory: String {
    case storage
    case widget
    case ui
    case macOS
    case setup
    case network
    case security
    case core
}

@available(macOS 11.0, *)
public enum Log {
    public static let subsystem: String = {
        // Prefer main bundle identifier when available; fall back to a stable name
        Bundle.main.bundleIdentifier ?? "PiStats"
    }()

    public static func logger(_ category: LogCategory) -> Logger {
        Logger(subsystem: subsystem, category: category.rawValue)
    }

    // Convenience per-category loggers
    public static let storage = Logger(subsystem: subsystem, category: LogCategory.storage.rawValue)
    public static let widget = Logger(subsystem: subsystem, category: LogCategory.widget.rawValue)
    public static let ui = Logger(subsystem: subsystem, category: LogCategory.ui.rawValue)
    public static let macOS = Logger(subsystem: subsystem, category: LogCategory.macOS.rawValue)
    public static let setup = Logger(subsystem: subsystem, category: LogCategory.setup.rawValue)
    public static let network = Logger(subsystem: subsystem, category: LogCategory.network.rawValue)
    public static let security = Logger(subsystem: subsystem, category: LogCategory.security.rawValue)
    public static let core = Logger(subsystem: subsystem, category: LogCategory.core.rawValue)
}


