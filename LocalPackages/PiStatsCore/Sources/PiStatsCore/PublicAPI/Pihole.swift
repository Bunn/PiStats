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
    public let secure: Bool
    public let version: PiholeVersion
    public let piMonitor: PiMonitorEnvironment?

    public init(name: String,
                address: String,
                version: PiholeVersion = .v6,
                port: Int = 80,
                secure: Bool = false,
                token: String? = nil,
                piMonitor: PiMonitorEnvironment? = nil,
                uuid: UUID = UUID()) {
        self.uuid = uuid
        self.name = name
        self.address = address
        self.token = token
        self.version = version
        self.port = port
        self.secure = secure
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

    public init(id: UUID = UUID(), timestamp: Date, blocked: Int, forwarded: Int) {
        self.id = id
        self.timestamp = timestamp
        self.blocked = blocked
        self.forwarded = forwarded
    }
}

// MARK: - TopDomainsResult Model

public struct TopDomainsResult: Sendable {
    public let topPermitted: [TopDomainItem]
    public let topBlocked: [TopDomainItem]
    
    public init(topPermitted: [TopDomainItem], topBlocked: [TopDomainItem]) {
        self.topPermitted = topPermitted
        self.topBlocked = topBlocked
    }
}

public struct TopDomainItem: Identifiable, Sendable {
    public let id = UUID()
    public let domain: String
    public let count: Int

    public init(domain: String, count: Int) {
        self.domain = domain
        self.count = count
    }
}

// MARK: - TopClientsResult Model

public struct TopClientsResult: Sendable {
    public let topActive: [TopClientItem]
    public let topBlocked: [TopClientItem]

    public init(topActive: [TopClientItem], topBlocked: [TopClientItem]) {
        self.topActive = topActive
        self.topBlocked = topBlocked
    }
}

public struct TopClientItem: Identifiable, Sendable {
    public let id = UUID()
    public let ip: String
    public let name: String
    public let count: Int

    public init(ip: String, name: String, count: Int) {
        self.ip = ip
        self.name = name
        self.count = count
    }

    public var displayName: String {
        name.isEmpty ? ip : name
    }
}

// MARK: - QueryTypesResult Model

public struct QueryTypesResult: Sendable {
    public let types: [QueryTypeItem]

    public init(types: [QueryTypeItem]) {
        self.types = types
    }
}

public struct QueryTypeItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    /// Share of total queries for this type, 0...100.
    public let percentage: Double

    public init(name: String, percentage: Double) {
        self.name = name
        self.percentage = percentage
    }
}

// MARK: - UpstreamsResult Model

public struct UpstreamsResult: Sendable {
    public let upstreams: [UpstreamItem]

    public init(upstreams: [UpstreamItem]) {
        self.upstreams = upstreams
    }
}

public struct UpstreamItem: Identifiable, Sendable {
    public let id = UUID()
    public let name: String
    public let ip: String
    /// Share of total queries handled by this upstream, 0...100.
    public let percentage: Double

    public init(name: String, ip: String, percentage: Double) {
        self.name = name
        self.ip = ip
        self.percentage = percentage
    }

    public var displayName: String {
        name.isEmpty ? ip : name
    }
}

// MARK: - Query Log Model

public enum QueryStatus: Sendable, Equatable {
    case blocked
    case forwarded
    case cached
    case unknown
}

public struct QueryLogEntry: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: Date
    public let domain: String
    /// Display name of the requesting client (hostname when known, else IP).
    public let client: String
    public let type: String
    public let status: QueryStatus

    public init(timestamp: Date, domain: String, client: String, type: String, status: QueryStatus) {
        self.timestamp = timestamp
        self.domain = domain
        self.client = client
        self.type = type
        self.status = status
    }
}

// MARK: - Pihole Health Model

public struct PiholeHealth: Sendable {
    public let coreVersion: String?
    public let webVersion: String?
    public let ftlVersion: String?
    public let updateAvailable: Bool
    /// Diagnosis/warning messages reported by FTL (v6 only; empty on v5).
    public let messages: [DiagnosisMessage]

    public init(coreVersion: String?,
                webVersion: String?,
                ftlVersion: String?,
                updateAvailable: Bool,
                messages: [DiagnosisMessage]) {
        self.coreVersion = coreVersion
        self.webVersion = webVersion
        self.ftlVersion = ftlVersion
        self.updateAvailable = updateAvailable
        self.messages = messages
    }
}

public struct DiagnosisMessage: Identifiable, Sendable {
    public let id = UUID()
    public let text: String
    /// When FTL recorded the message (v6 only).
    public let timestamp: Date?

    public init(text: String, timestamp: Date? = nil) {
        self.text = text
        self.timestamp = timestamp
    }
}
