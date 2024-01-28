//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/22/24.
//

import Foundation

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
        assertionFailure("V5 should not call this API")
        return Credentials.SessionID(sid: "", csrf: "")
    }

    func fetchSummary(serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary {
        guard let token = credentials.apiToken else {
            throw PiholeServiceError.noAPIToken
        }

        var urlComponents = URLComponentsForSettings(serverSettings)

        urlComponents.path = "/admin/api.php"
        urlComponents.queryItems = [
            URLQueryItem(name: "summaryRaw", value: ""),
            URLQueryItem(name: "auth", value: token)
        ]

        guard let url = urlComponents.url else {
            throw PiholeServiceError.cantGenerateURL
        }

        let request = URLRequest(url: url)
        let (data, _) = try await urlSession.data(for: request)

        do {
            return try JSONDecoder().decode(SummaryV5.self, from: data)
        } catch {
            throw PiholeServiceError.cantDecodeData(data: data)
        }
    }

    // TODO: Refactor this
    private func URLComponentsForSettings(_ settings: ServerSettings) -> URLComponents {
        var components = URLComponents()
        components.scheme = settings.requestProtocol.rawValue
        components.host = settings.host
        components.port = settings.port
        return components
    }

}
