//
//  PiholeV5Service.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

private enum ServicePath {
    case summary

    var queryItems: [URLQueryItem] {
        switch self {
        case .summary:
            return [URLQueryItem(name: "summaryRaw", value: "")]
        }
    }

    var path: String {
        switch self {
        case .summary:
            return "/admin/api.php"
        }
    }
}

struct PiholeV5Service: PiholeService {
    public let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    func setStatus(_ status: Pihole.Status, serverSettings: ServerSettings, credentials: Credentials) async throws {

    }

    func fetchStatus(serverSettings: ServerSettings, credentials: Credentials) async throws -> Pihole.Status {
        return .disabled
    }
    
    func fetchSystemInfo(serverSettings: ServerSettings, credentials: Credentials) async throws -> SystemInfo {
        throw PiholeServiceError.notImplementedByPiholeVersion
    }

    func fetchSensorData(serverSettings: ServerSettings, credentials: Credentials) async throws -> SensorData {
        throw PiholeServiceError.notImplementedByPiholeVersion
    }

    func authenticate(serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID {
        throw PiholeServiceError.notImplementedByPiholeVersion
    }

    func fetchSummary(serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary {
        let data: SummaryV5 = try await fetchData(serverSettings: serverSettings, path: .summary, credentials: credentials)
        return data
    }

    private func fetchData<ServerData: Decodable>(serverSettings: ServerSettings,
                                                  path: ServicePath,
                                                  httpMethod: HTTPMethod = .GET,
                                                  httpBody: Data? = nil,
                                                  credentials: Credentials) async throws -> ServerData {
        guard let token = credentials.apiToken else {
            throw PiholeServiceError.noAPIToken
        }

        var urlComponents = ServerSettings.URLComponentsForSettings(serverSettings)

        urlComponents.path = path.path
        urlComponents.queryItems = [
            URLQueryItem(name: "auth", value: token)
        ]
        urlComponents.queryItems?.append(contentsOf: path.queryItems)

        guard let url = urlComponents.url else {
            throw PiholeServiceError.cantGenerateURL
        }

        let request = URLRequest(url: url)
        let (data, _) = try await urlSession.data(for: request)

        do {
            return try JSONDecoder().decode(ServerData.self, from: data)
        } catch {
            throw PiholeServiceError.cantDecodeData(data: data)
        }
    }
}
