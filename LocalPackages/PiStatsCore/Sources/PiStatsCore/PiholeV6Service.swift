//
//  PiholeV6Service.swift
//  PiStatsCore
//
//  Created by Fernando Bunn on 28/01/2025.
//

import Foundation
import OSLog

internal final class PiholeV6Service: PiholeService {
    public let pihole: Pihole
    private let authActor = AuthActor()
    private let urlSession: URLSession

    init(_ pihole: Pihole, urlSession: URLSession = .shared) {
        self.pihole = pihole
        self.urlSession = urlSession
    }
    
    private struct PiholeV6AuthResponse: Codable, Sendable {
        let sid: String
        let csrf: String
    }

    func fetchSummary() async throws -> PiholeSummary {
        Log.network.info("📊 [V6] Fetching summary for \(self.self.pihole.name)")
        
        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .summary)
        let json = try await fetchJSON(from: url, with: authResponse)

        let queries = json[JSONKeys.queries.rawValue] as? [String: Any] ?? [:]
        let gravity = json[JSONKeys.gravity.rawValue] as? [String: Any] ?? [:]

        let summary = PiholeSummary(
            domainsBeingBlocked: gravity[JSONKeys.domainsBeingBlocked.rawValue] as? Int ?? 0,
            queries: queries[JSONKeys.total.rawValue] as? Int ?? 0,
            adsBlocked: queries[JSONKeys.blocked.rawValue] as? Int ?? 0,
            adsPercentageToday: queries[JSONKeys.percentBlocked.rawValue] as? Double ?? 0.0,
            uniqueDomains: queries[JSONKeys.uniqueDomains.rawValue] as? Int ?? 0,
            queriesForwarded: queries[JSONKeys.forwarded.rawValue] as? Int ?? 0
        )
        
        Log.network.info("✅ [V6] Summary fetched for \(self.self.pihole.name) - Queries: \(summary.queries), Blocked: \(summary.adsBlocked)")
        return summary
    }

    func fetchStatus() async throws -> PiholeStatus {
        Log.network.info("🔍 [V6] Fetching status for \(self.pihole.name)")
        
        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .blocking)
        let json = try await fetchJSON(from: url, with: authResponse)

        let statusString = json[JSONKeys.blocking.rawValue] as? String ?? BlockingStatus.unknown.rawValue
        guard let status = PiholeStatus(rawValue: statusString) else {
            Log.network.error("❌ [V6] Unknown status received for \(self.pihole.name): \(statusString)")
            throw PiholeServiceError.unknownStatus
        }
        
        Log.network.info("✅ [V6] Status fetched for \(self.pihole.name): \(status.rawValue)")
        return status
    }

    func fetchHistory() async throws -> [HistoryItem] {
        Log.network.info("📈 [V6] Fetching history for \(self.pihole.name)")
        
        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .history)
        let json = try await fetchJSON(from: url, with: authResponse)

        guard let historyArray = json[JSONKeys.history.rawValue] as? [[String: Any]] else {
            Log.network.error("❌ [V6] Failed to parse history data for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let historyItems: [HistoryItem] = historyArray.compactMap { item in
            guard let timestamp = item[JSONKeys.timestamp.rawValue] as? TimeInterval,
                  let blocked = item[JSONKeys.blocked.rawValue] as? Int,
                  let forwarded = item[JSONKeys.forwarded.rawValue] as? Int,
                  let cached = item[JSONKeys.cached.rawValue] as? Int else {
                return nil
            }
            return HistoryItem(timestamp: Date(timeIntervalSince1970: timestamp), blocked: blocked, forwarded: forwarded + cached)
        }
        
        Log.network.info("✅ [V6] History fetched for \(self.pihole.name) - \(historyItems.count) items")
        return historyItems
    }

    func fetchTopDomains(count: Int) async throws -> TopDomainsResult {
        Log.network.info("🏆 [V6] Fetching top domains for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)

        let permittedURL = try makeURL(for: self.pihole, endpoint: .topDomains, queryItems: [
            URLQueryItem(name: "count", value: "\(count)")
        ])
        let blockedURL = try makeURL(for: self.pihole, endpoint: .topDomains, queryItems: [
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "blocked", value: "true")
        ])

        async let permittedJSON = fetchJSON(from: permittedURL, with: authResponse)
        async let blockedJSON = fetchJSON(from: blockedURL, with: authResponse)

        let (permitted, blocked) = try await (permittedJSON, blockedJSON)

        let topPermitted = parseTopDomains(from: permitted)
        let topBlocked = parseTopDomains(from: blocked)

        Log.network.info("✅ [V6] Top domains fetched for \(self.pihole.name) - \(topPermitted.count) permitted, \(topBlocked.count) blocked")
        return TopDomainsResult(topPermitted: topPermitted, topBlocked: topBlocked)
    }

    func fetchTopClients(count: Int) async throws -> TopClientsResult {
        Log.network.info("👥 [V6] Fetching top clients for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)

        let activeURL = try makeURL(for: self.pihole, endpoint: .topClients, queryItems: [
            URLQueryItem(name: "count", value: "\(count)")
        ])
        let blockedURL = try makeURL(for: self.pihole, endpoint: .topClients, queryItems: [
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "blocked", value: "true")
        ])

        async let activeJSON = fetchJSON(from: activeURL, with: authResponse)
        async let blockedJSON = fetchJSON(from: blockedURL, with: authResponse)

        let (active, blocked) = try await (activeJSON, blockedJSON)

        let topActive = parseTopClients(from: active)
        let topBlocked = parseTopClients(from: blocked)

        Log.network.info("✅ [V6] Top clients fetched for \(self.pihole.name) - \(topActive.count) active, \(topBlocked.count) blocked")
        return TopClientsResult(topActive: topActive, topBlocked: topBlocked)
    }

    func enable() async throws -> PiholeStatus {
        try await setBlocking(.enable, for: self.pihole)
    }

    func disable(timer: Int?) async throws -> PiholeStatus {
        try await setBlocking(.disable, for: self.pihole, timer: timer)
    }
}

// MARK: - Private Methods

extension PiholeV6Service {

    private struct BlockingStatusData: Codable {
        let blocking: Bool
        let timer: Int?
    }

    private enum BlockingAction {
        case enable
        case disable
    }

    private func authenticate(_ pihole: Pihole) async throws -> PiholeV6AuthResponse {
        Log.network.info("🔐 [V6] Authenticating with \(self.pihole.name)")
        
        guard let token = pihole.token else {
            Log.network.error("❌ [V6] No token provided for \(self.pihole.name)")
            throw PiholeServiceError.missingToken
        }

        let url = try makeURL(for: self.pihole, endpoint: .auth)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["password": token])

        Log.network.debug("📤 [V6] Sending authentication request to \(url.absoluteString)")

        do {
            let (data, response) = try await urlSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Log.network.debug("🔐 [V6] Authentication response: \(httpResponse.statusCode)")
            }
            
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            if let error = json?[JSONKeys.error.rawValue] as? [String: Any],
               let key = error[JSONKeys.key.rawValue] as? String, key == JSONKeys.apiSeatsExceeded.rawValue {
                Log.network.error("❌ [V6] API seats exceeded for \(self.pihole.name)")
                throw PiholeServiceError.apiSeatsExceeded
            }

            guard let session = json?[JSONKeys.session.rawValue] as? [String: Any],
                  let sid = session[JSONKeys.sid.rawValue] as? String,
                  let csrf = session[JSONKeys.csrf.rawValue] as? String else {
                Log.network.error("❌ [V6] Invalid authentication response for \(self.pihole.name)")
                throw PiholeServiceError.invalidAuthenticationResponse
            }

            let authResponse = PiholeV6AuthResponse(sid: sid, csrf: csrf)
            await authActor.setAuth(authResponse)
            
            Log.network.info("✅ [V6] Successfully authenticated with \(self.pihole.name)")
            return authResponse
        } catch {
            Log.network.error("💥 [V6] Authentication failed for \(self.pihole.name): \(error.localizedDescription)")
            throw PiholeServiceError.networkError(error)
        }
    }

    private func ensureAuthenticated(_ pihole: Pihole) async throws -> PiholeV6AuthResponse {
        if let sessionAuth = await authActor.getAuth() {
            return sessionAuth
        } else {
            return try await authenticate(self.pihole)
        }
    }

    private func makeURL(for pihole: Pihole, endpoint: Endpoint, queryItems: [URLQueryItem] = []) throws -> URL {
        let scheme = pihole.secure ? "https" : "http"
        let portString = ":\(pihole.port)"
        
        guard var components = URLComponents(string: "\(scheme)://\(pihole.address)\(portString)/api/\(endpoint.rawValue)") else {
            throw PiholeServiceError.badURL
        }
        
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw PiholeServiceError.badURL
        }
        return url
    }

    private func parseTopDomains(from json: [String: Any]) -> [TopDomainItem] {
        guard let domains = json["domains"] as? [[String: Any]] else {
            return []
        }
        return domains.compactMap { item in
            guard let domain = item["domain"] as? String,
                  let count = item["count"] as? Int else {
                return nil
            }
            return TopDomainItem(domain: domain, count: count)
        }
    }

    private func parseTopClients(from json: [String: Any]) -> [TopClientItem] {
        guard let clients = json["clients"] as? [[String: Any]] else {
            return []
        }
        return clients.compactMap { item in
            guard let ip = item["ip"] as? String,
                  let count = item["count"] as? Int else {
                return nil
            }
            let name = item["name"] as? String ?? ""
            return TopClientItem(ip: ip, name: name, count: count)
        }
    }

    private func fetchJSON(from url: URL, with auth: PiholeV6AuthResponse) async throws -> [String: Any] {
        Log.network.info("🌐 [V6] Starting API request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.addValue(auth.sid, forHTTPHeaderField: HeaderFields.sid)
        request.addValue(auth.csrf, forHTTPHeaderField: HeaderFields.csrf)

        do {
            let (data, response) = try await urlSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Log.network.info("✅ [V6] Received response: \(httpResponse.statusCode) for \(url.absoluteString)")
                Log.network.debug("📊 [V6] Response data size: \(data.count) bytes")
                
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    Log.network.warning("🔐 [V6] Session expired or unauthorized for \(url.absoluteString), clearing cached auth")
                    await clearSessionAuth()
                    throw PiholeServiceError.invalidAuthenticationResponse
                }
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                Log.network.error("❌ [V6] Failed to parse JSON response from \(url.absoluteString)")
                throw PiholeServiceError.cannotParseResponse
            }
            
            Log.network.debug("🔍 [V6] Successfully parsed JSON with keys: \(Array(json.keys))")
            return json
        } catch let error as PiholeServiceError {
            throw error
        } catch {
            Log.network.error("💥 [V6] Network error for \(url.absoluteString): \(error.localizedDescription)")
            await clearSessionAuth()
            throw PiholeServiceError.networkError(error)
        }
    }

    private func postJSON(_ jsonData: Codable, on url: URL, with auth: PiholeV6AuthResponse) async throws -> [String: Any] {
        Log.network.info("📤 [V6] Starting POST request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(auth.sid, forHTTPHeaderField: HeaderFields.sid)
        request.addValue(auth.csrf, forHTTPHeaderField: HeaderFields.csrf)

        do {
            request.httpBody = try JSONEncoder().encode(jsonData)
            Log.network.debug("📝 [V6] Encoded request body for \(url.absoluteString)")
        } catch {
            Log.network.error("❌ [V6] Failed to encode request body: \(error.localizedDescription)")
            throw PiholeServiceError.encodingError(error)
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Log.network.info("✅ [V6] POST response: \(httpResponse.statusCode) for \(url.absoluteString)")
                Log.network.debug("📊 [V6] Response data size: \(data.count) bytes")
                
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    Log.network.warning("🔐 [V6] Session expired or unauthorized for \(url.absoluteString), clearing cached auth")
                    await clearSessionAuth()
                    throw PiholeServiceError.invalidAuthenticationResponse
                }
            }

            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                Log.network.error("❌ [V6] Failed to parse POST response from \(url.absoluteString)")
                throw PiholeServiceError.cannotParseResponse
            }

            Log.network.debug("🔍 [V6] Successfully parsed POST response with keys: \(Array(json.keys))")
            return json
        } catch let error as PiholeServiceError {
            throw error
        } catch {
            Log.network.error("💥 [V6] POST request failed for \(url.absoluteString): \(error.localizedDescription)")
            await clearSessionAuth()
            throw PiholeServiceError.networkError(error)
        }
    }

    private func setBlocking(_ action: BlockingAction, for pihole: Pihole, timer: Int? = nil) async throws -> PiholeStatus {
        let actionName = action == .enable ? "enable" : "disable"
        Log.network.info("🔄 [V6] Setting blocking action: \(actionName) for \(self.pihole.name)")
        
        if let timer = timer {
            Log.network.debug("⏱️ [V6] Disable timer set to: \(timer) seconds")
        }
        
        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .blocking)

        let shouldEnable = (action == .enable)
        let blockingData = BlockingStatusData(blocking: shouldEnable, timer: timer)

        let result = try await postJSON(blockingData, on: url, with: authResponse)

        guard let blockingStatus = result[JSONKeys.blocking.rawValue] as? String else {
            Log.network.error("❌ [V6] Failed to parse blocking action response for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let status: PiholeStatus = blockingStatus == BlockingStatus.enabled.rawValue ? .enabled : .disabled
        Log.network.info("🎯 [V6] Blocking action completed. New status: \(status.rawValue) for \(self.pihole.name)")
        return status
    }
}

// MARK: - Data types

extension PiholeV6Service {

    private enum Endpoint: String {
        case summary = "stats/summary"
        case blocking = "dns/blocking"
        case history = "history"
        case auth = "auth"
        case topDomains = "stats/top_domains"
        case topClients = "stats/top_clients"
    }

    private enum JSONKeys: String {
        case queries
        case blocked
        case total
        case percentBlocked = "percent_blocked"
        case uniqueDomains = "unique_domains"
        case domainsBeingBlocked = "domains_being_blocked"
        case forwarded
        case history
        case timestamp
        case cached
        case session
        case sid
        case csrf
        case blocking
        case gravity
        case error
        case apiSeatsExceeded = "api_seats_exceeded"
        case key
    }

    private enum BlockingStatus: String {
        case enabled
        case disabled
        case unknown
    }

    private enum HeaderFields {
        static let csrf = "X-FTL-CSRF"
        static let sid = "X-FTL-SID"
    }
}

/// Ensures thread-safe session authentication for Pi-hole v6
///
/// Uses an actor to serialize access to `sessionAuth`, preventing data races.
extension PiholeV6Service {
    private actor AuthActor {
        private var sessionAuth: PiholeV6AuthResponse?

        func setAuth(_ auth: PiholeV6AuthResponse?) {
            self.sessionAuth = auth
        }

        func getAuth() -> PiholeV6AuthResponse? {
            self.sessionAuth
        }
        
        func clearAuth() {
            self.sessionAuth = nil
        }
    }

    private func setSessionAuth(_ auth: PiholeV6AuthResponse?) async {
        await authActor.setAuth(auth)
    }

    private func getSessionAuth() async -> PiholeV6AuthResponse? {
        await authActor.getAuth()
    }
    
    private func clearSessionAuth() async {
        await authActor.clearAuth()
    }
}
