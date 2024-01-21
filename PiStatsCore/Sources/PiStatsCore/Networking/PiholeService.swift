//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/21/24.
//

import Foundation

public enum PiholeServiceError: Error {
    case cantGenerateURL
    case cantDecodeSummary
    case noAPIToken
    case noAPIPassword
    case noCredentials
}

protocol PiholeService {
    init(session: URLSession)
    func fetchSummary(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary
    func authenticate(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID
}

struct PiholeV6Service: PiholeService {

    struct APIResponse: Codable {
        let session: Credentials.SessionID
    }

    public let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }
    
    // TODO: Refactor this
    func fetchSummary(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary {
        var sessionID: Credentials.SessionID

        guard credentials.applicationPassword != nil else {
            throw PiholeServiceError.noAPIPassword
        }

        if credentials.sessionID == nil {
            sessionID = try await authenticate(serverSettings, credentials: credentials)
        } else {
            sessionID = credentials.sessionID!
        }


        var urlComponents = URLComponentsForSettings(serverSettings)
        urlComponents.path = "/api/stats/summary"

        guard let url = urlComponents.url else {
            throw PiholeServiceError.cantGenerateURL
        }

        var request = URLRequest(url: url)
        request.setValue(sessionID.csrf, forHTTPHeaderField: "X-FTL-CSRF")
        request.setValue(sessionID.sid, forHTTPHeaderField: "X-FTL-SID")

        let (data, _) = try await urlSession.data(for: request)

        do {
            return try JSONDecoder().decode(SummaryV6.self, from: data)
        } catch {
            throw PiholeServiceError.cantDecodeSummary
        }
    }
    
    func authenticate(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID {
        guard let password = credentials.applicationPassword else {
            throw PiholeServiceError.noAPIPassword
        }

        var urlComponents = URLComponentsForSettings(serverSettings)
        urlComponents.path = "/api/auth"

        guard let url = urlComponents.url else {
            throw PiholeServiceError.cantGenerateURL
        }

        var request = URLRequest(url: url)
        let requestBody = ["password": password]
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, _) = try await urlSession.data(for: request)

        let decoder = JSONDecoder()
        do {
            let apiResponse = try decoder.decode(APIResponse.self, from: data)
            // Now `apiResponse` contains the parsed data
            print(apiResponse.session.sid) // Access the SID
            print(apiResponse.session.csrf) // Access the CSRF
            return apiResponse.session
        } catch {
            print("Error parsing the API response: \(error)")
            throw PiholeServiceError.noAPIToken
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


struct PiholeV5Service: PiholeService {
    public let urlSession: URLSession

    init(session: URLSession = .shared) {
        self.urlSession = session
    }

    func authenticate(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Credentials.SessionID {
        assertionFailure("V5 should not call this API")
        return Credentials.SessionID(sid: "", csrf: "")
    }

    func fetchSummary(_ serverSettings: ServerSettings, credentials: Credentials) async throws -> Summary {
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
            throw PiholeServiceError.cantDecodeSummary
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
