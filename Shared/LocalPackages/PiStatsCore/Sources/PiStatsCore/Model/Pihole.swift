//
//  Pihole.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

public struct ServerSettings {
    public enum Version: String, Codable {
        case v5
        case v6
    }

    public enum RequestProtocol: String, Codable {
        case http
        case https
    }

    var version: Version
    var host: String
    var port: Int?
    var requestProtocol: RequestProtocol = .http

    public init(version: ServerSettings.Version, host: String, port: Int? = nil, requestProtocol: ServerSettings.RequestProtocol = .http) {
        self.version = version
        self.host = host
        self.port = port
        self.requestProtocol = requestProtocol
    }
}

extension ServerSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case version
        case host
        case port
        case requestProtocol
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version.rawValue, forKey: .version)
        try container.encode(host, forKey: .host)
        try container.encodeIfPresent(port, forKey: .port)
        try container.encode(requestProtocol.rawValue, forKey: .requestProtocol)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Version.self, forKey: .version)
        self.host = try container.decode(String.self, forKey: .host)
        self.port = try container.decodeIfPresent(Int.self, forKey: .port)
        self.requestProtocol = try container.decode(RequestProtocol.self, forKey: .requestProtocol)
    }
}


@Observable
final public class Pihole {
    public enum Status: String {
        case enabled
        case disabled
        case unknown
    }

    public var serverSettings: ServerSettings
    public var credentials: Credentials
    public var name: String

    public var status: Status = .unknown
    public var summary: Summary?
    public var sensorData: SensorData?
    public var systemInfo: SystemInfo?
    public var DNSQueries: DNSQueries?
    public private(set) var errors: [PiholeOperationErrorLog]
    public let id = UUID()

    public init(serverSettings: ServerSettings, credentials: Credentials, name: String? = nil) {
        self.serverSettings = serverSettings
        self.credentials = credentials
        self.errors = [PiholeOperationErrorLog]()

        if let name = name {
            self.name = name
        } else {
            self.name = serverSettings.host
        }
    }

    func addErrorLog(_ error: Error) {
        self.errors.append(PiholeOperationErrorLog.logError(error))
    }
}

struct Queries {
    let domainsOverTime: [TimestampedRequest]
    let adsOverTime: [TimestampedRequest]
}

struct TimestampedRequest {
    let timestamp: Int
    let value: Int
}

extension Pihole: CustomDebugStringConvertible {
    public var debugDescription: String {
        var description = "Pihole - Name: \(name), Status: \(status.rawValue)\n"

        if let summary = summary {
            description += "Summary: \(summary)\n"
        }

        if let sensorData = sensorData {
            description += "Sensor Data: \(sensorData)\n"
        }

        if let systemInfo = systemInfo {
            description += "System Info: \(systemInfo)\n"
        }

        if let DNSQueries = DNSQueries {
            description += "DNS Queries: \(DNSQueries)\n"
        }

        if !errors.isEmpty {
            description += "Errors: \(errors)\n"
        }

        return description
    }
}
