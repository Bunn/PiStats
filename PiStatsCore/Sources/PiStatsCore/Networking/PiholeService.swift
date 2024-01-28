//
//  PiholeService.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case GET
    case POST
}

public enum PiholeServiceError: Error {
    case cantGenerateURL
    case cantDecodeData(data: Data?)
    case noAPIToken
    case noAPIPassword
    case noCredentials
    case notImplementedByPiholeVersion
}

protocol PiholeService {
    init(session: URLSession)
    func fetchSummary(serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary
    func authenticate(serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID
    func setStatus(_ status: Pihole.Status, serverSettings: ServerSettings, credentials: Credentials) async throws
    func fetchStatus(serverSettings: ServerSettings, credentials: Credentials) async throws -> Pihole.Status
    func fetchSystemInfo(serverSettings: ServerSettings, credentials: Credentials) async throws -> SystemInfo
    func fetchSensorData(serverSettings: ServerSettings, credentials: Credentials) async throws -> SensorData
}

extension ServerSettings {

    static func URLComponentsForSettings(_ settings: ServerSettings) -> URLComponents {
        var components = URLComponents()
        components.scheme = settings.requestProtocol.rawValue
        components.host = settings.host
        components.port = settings.port
        return components
    }
}
