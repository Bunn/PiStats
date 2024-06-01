//
//  Pihole.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

public struct ServerSettings {
    public enum Version {
        case v5
        case v6
    }
    
    public enum RequestProtocol: String {
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

@MainActor
@Observable
public class Pihole {
        public enum Status: String {
        case enabled
        case disabled
        case unknown
    }
    
    public var serverSettings: ServerSettings
    public var status: Status = .unknown
    public var summary: Summary?
    public var sensorData: SensorData?
    public var systemInfo: SystemInfo?
    public var DNSQueries: DNSQueries?
    public private(set) var errors: [PiholeOperationErrorLog]
    var credentials: Credentials
    
    
    public init(serverSettings: ServerSettings, credentials: Credentials) {
        self.serverSettings = serverSettings
        self.credentials = credentials
        self.errors = [PiholeOperationErrorLog]()
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
