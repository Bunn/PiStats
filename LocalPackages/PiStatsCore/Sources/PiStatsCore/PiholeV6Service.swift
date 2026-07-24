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

    func fetchSystemMetrics() async throws -> PiMonitorMetrics {
        Log.network.info("🖥️ [V6] Fetching system metrics for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let systemURL = try makeURL(for: self.pihole, endpoint: .system)
        let sensorsURL = try makeURL(for: self.pihole, endpoint: .sensors)

        async let systemRequest = fetchJSON(from: systemURL, with: authResponse)
        async let sensorsRequest = fetchJSON(from: sensorsURL, with: authResponse)
        let (systemJSON, sensorsJSON) = try await (systemRequest, sensorsRequest)

        guard let system = systemJSON["system"] as? [String: Any],
              let uptime = Self.doubleValue(system["uptime"]),
              let memory = system["memory"] as? [String: Any],
              let ram = memory["ram"] as? [String: Any],
              let totalMemory = Self.intValue(ram["total"]),
              let freeMemory = Self.intValue(ram["free"]),
              let availableMemory = Self.intValue(ram["available"]),
              let cpu = system["cpu"] as? [String: Any],
              let load = cpu["load"] as? [String: Any],
              let rawLoad = load["raw"] as? [Any] else {
            Log.network.error("❌ [V6] Failed to parse system metrics for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let loadAverage = rawLoad.compactMap { Self.doubleValue($0) }
        guard loadAverage.count == rawLoad.count else {
            Log.network.error("❌ [V6] Failed to parse load averages for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let sensors = sensorsJSON["sensors"] as? [String: Any]
        let temperature = Self.celsiusTemperature(
            Self.doubleValue(sensors?["cpu_temp"]),
            unit: sensors?["unit"] as? String
        )
        let usedMemory = Self.intValue(ram["used"])
        let percentageUsed = Self.doubleValue(ram["%used"])

        let metrics = PiMonitorMetrics(
            socTemperature: temperature,
            uptime: uptime,
            loadAverage: loadAverage,
            kernelRelease: "",
            memory: PiMonitorMetrics.Memory(
                totalMemory: totalMemory,
                freeMemory: freeMemory,
                availableMemory: availableMemory,
                usedMemory: usedMemory,
                percentageUsed: percentageUsed
            )
        )

        Log.network.info("✅ [V6] System metrics fetched for \(self.pihole.name)")
        return metrics
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

    func fetchQueryTypes() async throws -> QueryTypesResult {
        Log.network.info("📊 [V6] Fetching query types for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .queryTypes)
        let json = try await fetchJSON(from: url, with: authResponse)

        guard let counts = json[JSONKeys.types.rawValue] as? [String: Int] else {
            Log.network.error("❌ [V6] Failed to parse query types for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let total = counts.values.reduce(0, +)
        let types = counts.compactMap { name, count -> QueryTypeItem? in
            guard count > 0 else { return nil }
            let percentage = total > 0 ? (Double(count) * 100) / Double(total) : 0
            return QueryTypeItem(name: name, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }

        Log.network.info("✅ [V6] Query types fetched for \(self.pihole.name) - \(types.count) types")
        return QueryTypesResult(types: types)
    }

    func fetchUpstreams() async throws -> UpstreamsResult {
        Log.network.info("🔀 [V6] Fetching upstreams for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .upstreams)
        let json = try await fetchJSON(from: url, with: authResponse)

        guard let upstreams = json[JSONKeys.upstreams.rawValue] as? [[String: Any]] else {
            Log.network.error("❌ [V6] Failed to parse upstreams for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let total = json[JSONKeys.totalQueries.rawValue] as? Int
            ?? upstreams.compactMap { $0["count"] as? Int }.reduce(0, +)

        let items = upstreams.compactMap { item -> UpstreamItem? in
            guard let count = item["count"] as? Int else { return nil }
            let name = item["name"] as? String ?? ""
            let ip = item["ip"] as? String ?? ""
            let port = item["port"] as? Int
            let percentage = total > 0 ? (Double(count) * 100) / Double(total) : 0
            return UpstreamItem(name: name, ip: ip, port: port, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }

        Log.network.info("✅ [V6] Upstreams fetched for \(self.pihole.name) - \(items.count) upstreams")
        return UpstreamsResult(upstreams: items)
    }

    func fetchQueries(count: Int) async throws -> [QueryLogEntry] {
        Log.network.info("📜 [V6] Fetching queries for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .queries, queryItems: [
            URLQueryItem(name: "length", value: "\(count)")
        ])
        let json = try await fetchJSON(from: url, with: authResponse)

        guard let queries = json["queries"] as? [[String: Any]] else {
            Log.network.error("❌ [V6] Failed to parse queries for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let entries: [QueryLogEntry] = queries.compactMap { item in
            guard let time = item["time"] as? TimeInterval,
                  let domain = item["domain"] as? String,
                  let type = item["type"] as? String else {
                return nil
            }
            let clientDict = item["client"] as? [String: Any]
            let clientName = clientDict?["name"] as? String
            let clientIP = clientDict?["ip"] as? String ?? ""
            let client = (clientName?.isEmpty == false) ? clientName! : clientIP
            let statusString = item["status"] as? String ?? ""
            return QueryLogEntry(
                timestamp: Date(timeIntervalSince1970: time),
                domain: domain,
                client: client,
                type: type,
                status: Self.queryStatus(fromV6Status: statusString)
            )
        }

        Log.network.info("✅ [V6] Queries fetched for \(self.pihole.name) - \(entries.count) entries")
        return entries
    }

    func fetchHealth() async throws -> PiholeHealth {
        Log.network.info("❤️ [V6] Fetching health for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let versionURL = try makeURL(for: self.pihole, endpoint: .version)
        let messagesURL = try makeURL(for: self.pihole, endpoint: .messages)

        async let versionJSON = fetchJSON(from: versionURL, with: authResponse)
        async let messagesJSON = fetchJSON(from: messagesURL, with: authResponse)
        let (versionData, messagesData) = try await (versionJSON, messagesJSON)

        let version = versionData["version"] as? [String: Any] ?? [:]
        func localVersion(_ component: String) -> String? {
            ((version[component] as? [String: Any])?["local"] as? [String: Any])?["version"] as? String
        }
        func remoteVersion(_ component: String) -> String? {
            ((version[component] as? [String: Any])?["remote"] as? [String: Any])?["version"] as? String
        }
        let updateAvailable = ["core", "web", "ftl"].contains { component in
            guard let local = localVersion(component),
                  let remote = remoteVersion(component),
                  !remote.isEmpty else { return false }
            return local != remote
        }

        let messagesArray = messagesData["messages"] as? [[String: Any]] ?? []
        let messages: [DiagnosisMessage] = messagesArray.compactMap { item in
            guard let text = item["plain"] as? String else { return nil }
            let timestamp = (item["timestamp"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
            return DiagnosisMessage(text: text, timestamp: timestamp)
        }

        Log.network.info("✅ [V6] Health fetched for \(self.pihole.name) - update: \(updateAvailable), \(messages.count) messages")
        return PiholeHealth(
            coreVersion: localVersion("core"),
            webVersion: localVersion("web"),
            ftlVersion: localVersion("ftl"),
            updateAvailable: updateAvailable,
            messages: messages
        )
    }

    func clearMessages() async throws {
        Log.network.info("🧹 [V6] Clearing messages for \(self.pihole.name)")

        let authResponse = try await ensureAuthenticated(self.pihole)
        let messagesURL = try makeURL(for: self.pihole, endpoint: .messages)
        let json = try await fetchJSON(from: messagesURL, with: authResponse)

        let ids = (json["messages"] as? [[String: Any]] ?? []).compactMap { $0["id"] as? Int }
        guard !ids.isEmpty else {
            Log.network.info("ℹ️ [V6] No messages to clear for \(self.pihole.name)")
            return
        }

        // FTL accepts multiple comma-separated IDs in the path.
        let idPath = ids.map(String.init).joined(separator: ",")
        let deleteURL = try makeURL(for: self.pihole, path: "info/messages/\(idPath)")
        try await delete(url: deleteURL, with: authResponse)

        Log.network.info("✅ [V6] Cleared \(ids.count) message(s) for \(self.pihole.name)")
    }

    func enable() async throws -> PiholeStatus {
        try await setBlocking(.enable, for: self.pihole)
    }

    func disable(timer: Int?) async throws -> PiholeStatus {
        try await setBlocking(.disable, for: self.pihole, timer: timer)
    }

    func updateGravity() async throws {
        Log.network.info("🌍 [V6] Updating gravity for \(self.pihole.name)")
        let authResponse = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .gravity)
        try await postAction(on: url, with: authResponse)
        Log.network.info("✅ [V6] Gravity update completed for \(self.pihole.name)")
    }

    func fetchAdlists() async throws -> [AdList] {
        Log.network.info("📃 [V6] Fetching adlists for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, endpoint: .lists)
        let json = try await fetchJSON(from: url, with: auth)
        return parseAdlists(from: json)
    }

    func setAdlist(_ adlist: AdList, enabled: Bool) async throws {
        Log.network.info("📃 [V6] Setting adlist \(adlist.address) enabled=\(enabled) for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)

        // The list address identifies the resource and must be percent-encoded
        // for the path (including its slashes).
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = adlist.address.addingPercentEncoding(withAllowedCharacters: allowed) ?? adlist.address

        let url = try makeURL(for: self.pihole, path: "lists/\(encoded)",
                              queryItems: [URLQueryItem(name: "type", value: adlist.type)])
        // FTL replaces the resource, so resend the existing fields with the
        // toggled `enabled` value.
        let body = AdListUpdateBody(type: adlist.type, comment: adlist.comment, groups: adlist.groups, enabled: enabled)
        try await put(body, on: url, with: auth)
    }

    func fetchDomains(type: DomainListType, kind: DomainListKind) async throws -> [DomainRule] {
        Log.network.info("🌐 [V6] Fetching \(type.rawValue)/\(kind.rawValue) domains for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)
        let url = try makeURL(for: self.pihole, path: "domains/\(type.rawValue)/\(kind.rawValue)")
        let json = try await fetchJSON(from: url, with: auth)
        let domains = json["domains"] as? [[String: Any]] ?? []
        return domains.compactMap { item in
            guard let domain = item["domain"] as? String else { return nil }
            return DomainRule(
                domain: domain,
                type: type,
                kind: kind,
                enabled: item["enabled"] as? Bool ?? true,
                comment: item["comment"] as? String,
                groups: item["groups"] as? [Int] ?? [0]
            )
        }
    }

    func addDomains(_ domains: [DomainRule]) async throws {
        guard !domains.isEmpty else { return }
        Log.network.info("➕ [V6] Adding \(domains.count) domain rule(s) for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)
        // The POST endpoint is per bucket, so group rules by (type, kind).
        let buckets = Dictionary(grouping: domains) { DomainBucket(type: $0.type, kind: $0.kind) }
        for (bucket, rules) in buckets {
            let url = try makeURL(for: self.pihole, path: "domains/\(bucket.type.rawValue)/\(bucket.kind.rawValue)")
            let body = AddDomainsBody(
                domain: rules.map(\.domain),
                comment: rules.first?.comment,
                groups: rules.first?.groups ?? [0],
                enabled: rules.first?.enabled ?? true
            )
            _ = try await postJSON(body, on: url, with: auth)
        }
    }

    func removeDomains(_ domains: [DomainRule]) async throws {
        guard !domains.isEmpty else { return }
        Log.network.info("➖ [V6] Removing \(domains.count) domain rule(s) for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        for rule in domains {
            let encoded = rule.domain.addingPercentEncoding(withAllowedCharacters: allowed) ?? rule.domain
            let url = try makeURL(for: self.pihole, path: "domains/\(rule.type.rawValue)/\(rule.kind.rawValue)/\(encoded)")
            try await delete(url: url, with: auth)
        }
    }

    func setDomain(_ domain: DomainRule, enabled: Bool) async throws {
        Log.network.info("🔁 [V6] Setting \(domain.domain) enabled=\(enabled) for \(self.pihole.name)")
        let auth = try await ensureAuthenticated(self.pihole)
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let encoded = domain.domain.addingPercentEncoding(withAllowedCharacters: allowed) ?? domain.domain
        let url = try makeURL(for: self.pihole, path: "domains/\(domain.type.rawValue)/\(domain.kind.rawValue)/\(encoded)")
        let body = DomainUpdateBody(comment: domain.comment, groups: domain.groups, enabled: enabled)
        try await put(body, on: url, with: auth)
    }

    func fetchGravityLastUpdated() async throws -> Date? {
        // Derived from the most recent per-list `date_updated`, which gravity
        // stamps on each list it successfully pulls.
        let lists = try await fetchAdlists()
        return lists.compactMap { $0.dateUpdated }.max()
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

            Log.network.info("✅ [V6] Successfully authenticated with \(self.pihole.name)")
            return authResponse
        } catch let error as PiholeServiceError {
            Log.network.error("💥 [V6] Authentication failed for \(self.pihole.name): \(error.localizedDescription)")
            throw error
        } catch {
            Log.network.error("💥 [V6] Authentication failed for \(self.pihole.name): \(error.localizedDescription)")
            throw PiholeServiceError.networkError(error)
        }
    }

    private func ensureAuthenticated(_ pihole: Pihole) async throws -> PiholeV6AuthResponse {
        try await authActor.authentication {
            try await self.authenticate(pihole)
        }
    }

    private func makeURL(for pihole: Pihole, endpoint: Endpoint, queryItems: [URLQueryItem] = []) throws -> URL {
        try makeURL(for: pihole, path: endpoint.rawValue, queryItems: queryItems)
    }

    private func makeURL(for pihole: Pihole, path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        let scheme = pihole.secure ? "https" : "http"
        let portString = ":\(pihole.port)"

        guard var components = URLComponents(string: "\(scheme)://\(pihole.address)\(portString)/api/\(path)") else {
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

    private static func queryStatus(fromV6Status status: String) -> QueryStatus {
        switch status.uppercased() {
        case "FORWARDED":
            return .forwarded
        case "CACHE", "CACHE_STALE":
            return .cached
        case "RETRIED", "RETRIED_DNSSEC", "IN_PROGRESS":
            return .unknown
        default:
            // GRAVITY, DENYLIST, REGEX, EXTERNAL_BLOCKED_*, SPECIAL_DOMAIN, *_CNAME, …
            return status.isEmpty ? .unknown : .blocked
        }
    }

    private static func doubleValue(_ value: Any?) -> Double? {
        (value as? NSNumber)?.doubleValue
    }

    private static func intValue(_ value: Any?) -> Int? {
        (value as? NSNumber)?.intValue
    }

    private static func celsiusTemperature(_ value: Double?, unit: String?) -> Double? {
        guard let value else { return nil }

        switch unit?.uppercased() {
        case "F":
            return (value - 32) / 1.8
        case "K":
            return value - 273.15
        default:
            return value
        }
    }

    private func fetchJSON(
        from url: URL,
        with auth: PiholeV6AuthResponse,
        allowsAuthenticationRetry: Bool = true
    ) async throws -> [String: Any] {
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
                    await authActor.invalidate(auth)
                    guard allowsAuthenticationRetry else {
                        throw PiholeServiceError.invalidAuthenticationResponse
                    }
                    let refreshedAuth = try await ensureAuthenticated(pihole)
                    return try await fetchJSON(
                        from: url,
                        with: refreshedAuth,
                        allowsAuthenticationRetry: false
                    )
                }

                guard (200..<300).contains(httpResponse.statusCode) else {
                    throw PiholeServiceError.unknownStatus
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
                    await authActor.invalidate(auth)
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
            throw PiholeServiceError.networkError(error)
        }
    }

    private func delete(url: URL, with auth: PiholeV6AuthResponse) async throws {
        Log.network.info("🗑️ [V6] Starting DELETE request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.addValue(auth.sid, forHTTPHeaderField: HeaderFields.sid)
        request.addValue(auth.csrf, forHTTPHeaderField: HeaderFields.csrf)

        do {
            let (_, response) = try await urlSession.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    await authActor.invalidate(auth)
                    throw PiholeServiceError.invalidAuthenticationResponse
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    Log.network.error("❌ [V6] DELETE failed with status \(httpResponse.statusCode) for \(url.absoluteString)")
                    throw PiholeServiceError.unknownStatus
                }
            }
        } catch let error as PiholeServiceError {
            throw error
        } catch {
            Log.network.error("💥 [V6] DELETE request failed for \(url.absoluteString): \(error.localizedDescription)")
            throw PiholeServiceError.networkError(error)
        }
    }

    /// POSTs to an action endpoint and verifies a 2xx status. Used for endpoints
    /// like gravity that stream a progress log rather than returning JSON.
    private func postAction(on url: URL, with auth: PiholeV6AuthResponse) async throws {
        Log.network.info("📤 [V6] Starting action POST to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(auth.sid, forHTTPHeaderField: HeaderFields.sid)
        request.addValue(auth.csrf, forHTTPHeaderField: HeaderFields.csrf)

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    await authActor.invalidate(auth)
                    throw PiholeServiceError.invalidAuthenticationResponse
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    Log.network.error("❌ [V6] Action POST failed with status \(httpResponse.statusCode) for \(url.absoluteString)")
                    throw PiholeServiceError.unknownStatus
                }
            }
        } catch let error as PiholeServiceError {
            throw error
        } catch {
            Log.network.error("💥 [V6] Action POST failed for \(url.absoluteString): \(error.localizedDescription)")
            throw PiholeServiceError.networkError(error)
        }
    }

    private struct AdListUpdateBody: Codable {
        let type: String
        let comment: String?
        let groups: [Int]
        let enabled: Bool
    }

    private struct AddDomainsBody: Codable {
        let domain: [String]
        let comment: String?
        let groups: [Int]
        let enabled: Bool
    }

    /// Body for PUT /domains/{type}/{kind}/{domain} — type/kind/domain are in the path.
    private struct DomainUpdateBody: Codable {
        let comment: String?
        let groups: [Int]
        let enabled: Bool
    }

    /// Groups domain rules that share the same POST endpoint.
    private struct DomainBucket: Hashable {
        let type: DomainListType
        let kind: DomainListKind
    }

    /// PUTs a Codable body and verifies a 2xx status.
    private func put(_ body: Codable, on url: URL, with auth: PiholeV6AuthResponse) async throws {
        Log.network.info("📤 [V6] Starting PUT request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.addValue(auth.sid, forHTTPHeaderField: HeaderFields.sid)
        request.addValue(auth.csrf, forHTTPHeaderField: HeaderFields.csrf)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw PiholeServiceError.encodingError(error)
        }

        do {
            let (_, response) = try await urlSession.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                    await authActor.invalidate(auth)
                    throw PiholeServiceError.invalidAuthenticationResponse
                }
                guard (200...299).contains(httpResponse.statusCode) else {
                    Log.network.error("❌ [V6] PUT failed with status \(httpResponse.statusCode) for \(url.absoluteString)")
                    throw PiholeServiceError.unknownStatus
                }
            }
        } catch let error as PiholeServiceError {
            throw error
        } catch {
            Log.network.error("💥 [V6] PUT request failed for \(url.absoluteString): \(error.localizedDescription)")
            throw PiholeServiceError.networkError(error)
        }
    }

    private func parseAdlists(from json: [String: Any]) -> [AdList] {
        guard let lists = json["lists"] as? [[String: Any]] else { return [] }
        return lists.compactMap { item in
            guard let address = item["address"] as? String,
                  let type = item["type"] as? String else { return nil }
            let id = item["id"] as? Int ?? 0
            let enabled: Bool
            if let value = item["enabled"] as? Bool {
                enabled = value
            } else if let value = item["enabled"] as? Int {
                enabled = value != 0
            } else {
                enabled = true
            }
            let comment = item["comment"] as? String
            let groups = (item["groups"] as? [Int]) ?? []
            let dateUpdated: Date?
            if let ts = item["date_updated"] as? Double, ts > 0 {
                dateUpdated = Date(timeIntervalSince1970: ts)
            } else if let ts = item["date_updated"] as? Int, ts > 0 {
                dateUpdated = Date(timeIntervalSince1970: TimeInterval(ts))
            } else {
                dateUpdated = nil
            }
            return AdList(id: id, address: address, enabled: enabled, type: type, comment: comment, groups: groups, dateUpdated: dateUpdated)
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
        case queryTypes = "stats/query_types"
        case upstreams = "stats/upstreams"
        case queries = "queries"
        case version = "info/version"
        case messages = "info/messages"
        case system = "info/system"
        case sensors = "info/sensors"
        case gravity = "action/gravity"
        case lists = "lists"
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
        case types
        case upstreams
        case totalQueries = "total_queries"
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
        private var authenticationTask: Task<PiholeV6AuthResponse, Error>?

        func authentication(
            using operation: @escaping @Sendable () async throws -> PiholeV6AuthResponse
        ) async throws -> PiholeV6AuthResponse {
            if let sessionAuth {
                return sessionAuth
            }

            if let authenticationTask {
                return try await authenticationTask.value
            }

            let task = Task {
                try await operation()
            }
            authenticationTask = task

            do {
                let auth = try await task.value
                sessionAuth = auth
                authenticationTask = nil
                return auth
            } catch {
                authenticationTask = nil
                throw error
            }
        }

        func invalidate(_ auth: PiholeV6AuthResponse) {
            guard sessionAuth?.sid == auth.sid else { return }
            sessionAuth = nil
        }
    }
}
