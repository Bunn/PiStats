//
//  PiholeV6Service.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

private enum ServicePath: String {
    case summary = "/api/stats/summary"
    case auth = "/api/auth"
    case systemInfo = "/api/info/system"
    case sensorData = "/api/info/sensors"
}

private enum ServiceHeader {
    static let CSRF = "X-FTL-CSRF"
    static let SID = "X-FTL-SID"
}

private enum HTTPMethod: String {
    case GET
    case POST
}

struct PiholeV6Service: PiholeService {
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
        let data: SystemInfo = try await fetchData(serverSettings: serverSettings,
                                                         path: .systemInfo,
                                                         credentials: credentials)
        return data
    }

    func fetchSensorData(serverSettings: ServerSettings, credentials: Credentials) async throws -> SensorData {
        let data: SensorData = try await fetchData(serverSettings: serverSettings,
                                                         path: .sensorData,
                                                         credentials: credentials)
        return data
    }

    func fetchSummary(serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary {
        let data: SummaryV6 = try await fetchData(serverSettings: serverSettings,
                                                         path: .summary,
                                                         credentials: credentials)
        return data
    }

    func authenticate(serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID {
        guard let password = credentials.applicationPassword else {
            throw PiholeServiceError.noAPIPassword
        }

        let body = try JSONEncoder().encode(["password": password])

        let response: APIResponse = try await fetchData(serverSettings: serverSettings,
                                                        path: .auth,
                                                        shouldAuthenticateIfNoSession: false,
                                                        httpMethod: .POST,
                                                        httpBody: body,
                                                        credentials: credentials)

        return response.session
    }

    private func fetchData<ServerData: Decodable>(serverSettings: ServerSettings, 
                                                  path: ServicePath,
                                                  shouldAuthenticateIfNoSession: Bool = true,
                                                  httpMethod: HTTPMethod = .GET,
                                                  httpBody: Data? = nil,
                                                  credentials: Credentials) async throws -> ServerData {
        var sessionID: Credentials.SessionID

        guard credentials.applicationPassword != nil else {
            throw PiholeServiceError.noAPIPassword
        }


        var urlComponents = URLComponentsForSettings(serverSettings)
        urlComponents.path = path.rawValue

        guard let url = urlComponents.url else {
            throw PiholeServiceError.cantGenerateURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = httpBody


        if shouldAuthenticateIfNoSession {
            if credentials.sessionID == nil {
                sessionID = try await authenticate(serverSettings: serverSettings, credentials: credentials)
            } else {
                sessionID = credentials.sessionID!
            }

            request.setValue(sessionID.csrf, forHTTPHeaderField: ServiceHeader.CSRF)
            request.setValue(sessionID.sid, forHTTPHeaderField: ServiceHeader.SID)
        }
        let (data, _) = try await urlSession.data(for: request)

        do {
            return try JSONDecoder().decode(ServerData.self, from: data)
        } catch {
            print("ERROR \(error)")
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

private struct APIResponse: Codable {
    let session: Credentials.SessionID
}

private struct ErrorResponse: Codable {
    let error: Error
    let took: Double
}

private struct Error: Codable {
    let key: String
    let message: String
    let hint: String?
}
