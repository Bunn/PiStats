import Foundation

// MARK: - Pihole Model
public enum PiholeVersion: String, CaseIterable, Identifiable, Sendable {
    case v5
    case v6

    public var id: String { self.rawValue }

    public var userValue: String {
        switch self {
        case .v5:
            return "Version 5.x"
        case .v6:
            return "Version 6.x"
        }
    }
}

public struct Pihole: Sendable, Identifiable {
    public let uuid: UUID
    public let name: String
    public let address: String
    public let token: String?
    public let port: Int
    public let version: PiholeVersion
    public let piMonitor: PiMonitorEnvironment?
    
    public init(name: String,
                address: String,
                version: PiholeVersion = .v6,
                port: Int = 80,
                token: String? = nil,
                piMonitor: PiMonitorEnvironment? = nil,
                uuid: UUID = UUID()) {
        self.uuid = uuid
        self.name = name
        self.address = address
        self.token = token
        self.version = version
        self.port = port
        self.piMonitor = piMonitor
    }

    public var id: UUID {
        return uuid
    }
}

// MARK: - PiholeSummary Model

public struct PiholeSummary: Codable, Sendable {
    public let domainsBeingBlocked: Int
    public let queries: Int
    public let adsBlocked: Int
    public let adsPercentageToday: Double
    public let uniqueDomains: Int
    public let queriesForwarded: Int
    
    public init(domainsBeingBlocked: Int, queries: Int, adsBlocked: Int, adsPercentageToday: Double, uniqueDomains: Int, queriesForwarded: Int) {
        self.domainsBeingBlocked = domainsBeingBlocked
        self.queries = queries
        self.adsBlocked = adsBlocked
        self.adsPercentageToday = adsPercentageToday
        self.uniqueDomains = uniqueDomains
        self.queriesForwarded = queriesForwarded
    }
}

// MARK: - PiholeStatus Enum

public enum PiholeStatus: String, Codable, Sendable{
    case enabled
    case disabled
    case unknown
}

public struct HistoryItem: Codable, Identifiable, Sendable {
    public var id = UUID()
    public let timestamp: Date
    public let blocked: Int
    public let forwarded: Int
}
