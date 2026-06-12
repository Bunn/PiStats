//
//  PiholeV5Service.swift
//  PiStatsCore
//
//  Created by Fernando Bunn on 28/01/2025.
//
import Foundation
import OSLog

internal final class PiholeV5Service: PiholeService {
    public let pihole: Pihole
    private let urlSession: URLSession

    init(_ pihole: Pihole, urlSession: URLSession = .shared) {
        self.pihole = pihole
        self.urlSession = urlSession
    }

    func fetchSummary() async throws -> PiholeSummary {
        Log.network.info("📊 [V5] Fetching summary for \(self.pihole.name)")
        
        let url = try makeURL(for: self.pihole, endpoint: .summary)
        let json = try await fetchJSON(from: url)

        let summary = PiholeSummary(
            domainsBeingBlocked: json[JSONKeys.domainsBeingBlocked.rawValue] as? Int ?? 0,
            queries: json[JSONKeys.dnsQueriesToday.rawValue] as? Int ?? 0,
            adsBlocked: json[JSONKeys.adsBlockedToday.rawValue] as? Int ?? 0,
            adsPercentageToday: json[JSONKeys.adsPercentageToday.rawValue] as? Double ?? 0.0,
            uniqueDomains: json[JSONKeys.uniqueDomains.rawValue] as? Int ?? 0,
            queriesForwarded: json[JSONKeys.queriesForwarded.rawValue] as? Int ?? 0
        )
        
        Log.network.info("✅ [V5] Summary fetched for \(self.pihole.name) - Queries: \(summary.queries), Blocked: \(summary.adsBlocked)")
        return summary
    }

    func fetchStatus() async throws -> PiholeStatus {
        Log.network.info("🔍 [V5] Fetching status for \(self.pihole.name)")
        
        let url = try makeURL(for: self.pihole, endpoint: .status)
        let json = try await fetchJSON(from: url)

        guard let statusString = json[JSONKeys.status.rawValue] as? String else {
            Log.network.error("❌ [V5] No status found in response for \(self.pihole.name)")
            throw PiholeServiceError.unknownStatus
        }

        let status = PiholeStatus(rawValue: statusString) ?? .unknown
        Log.network.info("✅ [V5] Status fetched for \(self.pihole.name): \(status.rawValue)")
        return status
    }

    func fetchHistory() async throws -> [HistoryItem] {
        Log.network.info("📈 [V5] Fetching history for \(self.pihole.name)")
        
        let url = try makeURL(for: self.pihole, endpoint: .history)
        let json = try await fetchJSON(from: url)

        guard let domainsOverTime = json[JSONKeys.domainsOverTime.rawValue] as? [String: Int],
              let adsOverTime = json[JSONKeys.adsOverTime.rawValue] as? [String: Int] else {
            Log.network.error("❌ [V5] Failed to parse history data for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        let historyItems: [HistoryItem] = domainsOverTime.compactMap { (timestampString, forwarded) in
            guard let timestamp = TimeInterval(timestampString),
                  let blocked = adsOverTime[timestampString] else {
                return nil
            }
            return HistoryItem(timestamp: Date(timeIntervalSince1970: timestamp), blocked: blocked, forwarded: forwarded)
        }
        
        Log.network.info("✅ [V5] History fetched for \(self.pihole.name) - \(historyItems.count) items")
        return historyItems
    }

    func fetchTopDomains(count: Int) async throws -> TopDomainsResult {
        Log.network.info("🏆 [V5] Fetching top domains for \(self.pihole.name)")

        let url = try makeURL(for: self.pihole, endpoint: .custom("topItems=\(count)"))
        let json = try await fetchJSON(from: url)

        let topPermitted = parseDomainDictionary(json[JSONKeys.topQueries.rawValue] as? [String: Int] ?? [:])
        let topBlocked = parseDomainDictionary(json[JSONKeys.topAds.rawValue] as? [String: Int] ?? [:])

        Log.network.info("✅ [V5] Top domains fetched for \(self.pihole.name) - \(topPermitted.count) permitted, \(topBlocked.count) blocked")
        return TopDomainsResult(topPermitted: topPermitted, topBlocked: topBlocked)
    }

    func fetchTopClients(count: Int) async throws -> TopClientsResult {
        Log.network.info("👥 [V5] Fetching top clients for \(self.pihole.name)")

        let activeURL = try makeURL(for: self.pihole, endpoint: .custom("topClients=\(count)"))
        let blockedURL = try makeURL(for: self.pihole, endpoint: .custom("topClientsBlocked=\(count)"))

        async let activeJSON = fetchJSON(from: activeURL)
        async let blockedJSON = fetchJSON(from: blockedURL)

        let (active, blocked) = try await (activeJSON, blockedJSON)

        let topActive = parseClientDictionary(active[JSONKeys.topSources.rawValue] as? [String: Int] ?? [:])
        let topBlocked = parseClientDictionary(blocked[JSONKeys.topSourcesBlocked.rawValue] as? [String: Int] ?? [:])

        Log.network.info("✅ [V5] Top clients fetched for \(self.pihole.name) - \(topActive.count) active, \(topBlocked.count) blocked")
        return TopClientsResult(topActive: topActive, topBlocked: topBlocked)
    }

    func fetchQueryTypes() async throws -> QueryTypesResult {
        Log.network.info("📊 [V5] Fetching query types for \(self.pihole.name)")

        let url = try makeURL(for: self.pihole, endpoint: .custom("getQueryTypes"))
        let json = try await fetchJSON(from: url)

        guard let types = json[JSONKeys.queryTypes.rawValue] as? [String: Any] else {
            Log.network.error("❌ [V5] Failed to parse query types for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        // V5 already returns per-type percentages.
        let items = types.compactMap { name, value -> QueryTypeItem? in
            guard let percentage = (value as? NSNumber)?.doubleValue, percentage > 0 else { return nil }
            return QueryTypeItem(name: name, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }

        Log.network.info("✅ [V5] Query types fetched for \(self.pihole.name) - \(items.count) types")
        return QueryTypesResult(types: items)
    }

    func fetchUpstreams() async throws -> UpstreamsResult {
        Log.network.info("🔀 [V5] Fetching upstreams for \(self.pihole.name)")

        let url = try makeURL(for: self.pihole, endpoint: .custom("getForwardDestinations"))
        let json = try await fetchJSON(from: url)

        guard let destinations = json[JSONKeys.forwardDestinations.rawValue] as? [String: Any] else {
            Log.network.error("❌ [V5] Failed to parse forward destinations for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        // V5 keys are "ip#port|name" (e.g. "8.8.8.8#53|dns.google") or "name|name"
        // (e.g. "cache|cache"); values are percentages.
        let items = destinations.compactMap { key, value -> UpstreamItem? in
            guard let percentage = (value as? NSNumber)?.doubleValue, percentage > 0 else { return nil }
            let parts = key.components(separatedBy: "|")
            let name = parts.count > 1 ? parts[1] : ""
            let ip = (parts.first ?? key).components(separatedBy: "#").first ?? key
            return UpstreamItem(name: name, ip: ip, percentage: percentage)
        }
        .sorted { $0.percentage > $1.percentage }

        Log.network.info("✅ [V5] Upstreams fetched for \(self.pihole.name) - \(items.count) upstreams")
        return UpstreamsResult(upstreams: items)
    }

    func fetchQueries(count: Int) async throws -> [QueryLogEntry] {
        Log.network.info("📜 [V5] Fetching queries for \(self.pihole.name)")

        let url = try makeURL(for: self.pihole, endpoint: .custom("getAllQueries=\(count)"))
        let json = try await fetchJSON(from: url)

        guard let data = json[JSONKeys.data.rawValue] as? [[Any]] else {
            Log.network.error("❌ [V5] Failed to parse queries for \(self.pihole.name)")
            throw PiholeServiceError.cannotParseResponse
        }

        // V5 rows are positional: [timestamp, type, domain, client, status, …]
        let entries: [QueryLogEntry] = data.compactMap { row in
            guard row.count >= 5,
                  let timestamp = Self.timeInterval(from: row[0]),
                  let type = row[1] as? String,
                  let domain = row[2] as? String,
                  let client = row[3] as? String,
                  let statusCode = Self.intValue(from: row[4]) else {
                return nil
            }
            return QueryLogEntry(
                timestamp: Date(timeIntervalSince1970: timestamp),
                domain: domain,
                client: client,
                type: type,
                status: Self.queryStatus(fromV5Code: statusCode)
            )
        }

        Log.network.info("✅ [V5] Queries fetched for \(self.pihole.name) - \(entries.count) entries")
        return entries
    }

    func fetchHealth() async throws -> PiholeHealth {
        Log.network.info("❤️ [V5] Fetching health for \(self.pihole.name)")

        let url = try makeURL(for: self.pihole, endpoint: .custom("versions"))
        let json = try await fetchJSON(from: url)

        let updateAvailable = (json[JSONKeys.coreUpdate.rawValue] as? Bool ?? false)
            || (json[JSONKeys.webUpdate.rawValue] as? Bool ?? false)
            || (json[JSONKeys.ftlUpdate.rawValue] as? Bool ?? false)

        // V5 has no diagnosis-message endpoint.
        let health = PiholeHealth(
            coreVersion: json[JSONKeys.coreCurrent.rawValue] as? String,
            webVersion: json[JSONKeys.webCurrent.rawValue] as? String,
            ftlVersion: json[JSONKeys.ftlCurrent.rawValue] as? String,
            updateAvailable: updateAvailable,
            messages: []
        )

        Log.network.info("✅ [V5] Health fetched for \(self.pihole.name) - update: \(updateAvailable)")
        return health
    }

    func clearMessages() async throws {
        // V5 has no diagnosis-message endpoint; nothing to clear.
    }

    func enable() async throws -> PiholeStatus {
        try await setBlocking(.enable, for: self.pihole)
    }

    func disable(timer: Int?) async throws -> PiholeStatus {
        try await setBlocking(.disable, for: self.pihole, timer: timer)
    }
}

// MARK: - Private Methods

extension PiholeV5Service {

    private enum BlockingAction {
        case enable
        case disable
    }

    private func makeURL(for pihole: Pihole, endpoint: Endpoint) throws -> URL {
        let scheme = pihole.secure ? "https" : "http"
        let portString = ":\(pihole.port)"
        
        guard let url = URL(string: "\(scheme)://\(pihole.address)\(portString)/admin/api.php?\(endpoint.rawValue)&auth=\(pihole.token ?? "")") else {
            throw PiholeServiceError.badURL
        }
        return url
    }

    private func fetchJSON(from url: URL) async throws -> [String: Any] {
        Log.network.info("🌐 [V5] Starting API request to: \(url.absoluteString)")
        
        do {
            let (data, response) = try await urlSession.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                Log.network.info("✅ [V5] Received response: \(httpResponse.statusCode) for \(url.absoluteString)")
                Log.network.debug("📊 [V5] Response data size: \(data.count) bytes")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                Log.network.error("❌ [V5] Failed to parse JSON response from \(url.absoluteString)")
                throw PiholeServiceError.cannotParseResponse
            }
            
            Log.network.debug("🔍 [V5] Successfully parsed JSON with keys: \(Array(json.keys))")
            return json
        } catch {
            Log.network.error("💥 [V5] Network error for \(url.absoluteString): \(error.localizedDescription)")
            throw error
        }
    }

    private func parseDomainDictionary(_ dict: [String: Int]) -> [TopDomainItem] {
        dict.map { TopDomainItem(domain: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    private func parseClientDictionary(_ dict: [String: Int]) -> [TopClientItem] {
        dict.map { entry in
            // V5 format: "hostname|IP" or just "IP"
            let parts = entry.key.components(separatedBy: "|")
            let name = parts.count > 1 ? parts[0] : ""
            let ip = parts.count > 1 ? parts[1] : parts[0]
            return TopClientItem(ip: ip, name: name, count: entry.value)
        }
        .sorted { $0.count > $1.count }
    }

    private static func timeInterval(from value: Any) -> TimeInterval? {
        if let string = value as? String { return TimeInterval(string) }
        if let number = value as? NSNumber { return number.doubleValue }
        return nil
    }

    private static func intValue(from value: Any) -> Int? {
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    /// Maps V5 numeric query status codes to a coarse status.
    /// 2/14 = forwarded, 3 = cached, 1/4-11/15/16 = blocked variants.
    private static func queryStatus(fromV5Code code: Int) -> QueryStatus {
        switch code {
        case 2, 14:
            return .forwarded
        case 3:
            return .cached
        case 1, 4, 5, 6, 7, 8, 9, 10, 11, 15, 16:
            return .blocked
        default:
            return .unknown
        }
    }

    private func setBlocking(_ action: BlockingAction, for pihole: Pihole, timer: Int? = nil) async throws -> PiholeStatus {
        let endpoint: String
        switch action {
        case .enable:
            endpoint = "enable"
        case .disable:
            endpoint = "disable"
        }

        Log.network.info("🔄 [V5] Setting blocking action: \(endpoint) for \(pihole.name)")
        if let timer = timer {
            Log.network.debug("⏱️ [V5] Disable timer set to: \(timer) seconds")
        }

        let scheme = pihole.secure ? "https" : "http"
        let portString = ":\(pihole.port)"
        
        var urlComponents = URLComponents(string: "\(scheme)://\(pihole.address)\(portString)/admin/api.php")!
        urlComponents.queryItems = [
            URLQueryItem(name: endpoint, value: timer != nil ? "\(timer!)" : nil),
            URLQueryItem(name: "auth", value: pihole.token)
        ]

        guard let url = urlComponents.url else {
            Log.network.error("❌ [V5] Failed to construct URL for \(pihole.name)")
            throw PiholeServiceError.badURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        Log.network.debug("📤 [V5] Sending POST request to: \(url.absoluteString)")

        do {
            let (data, response) = try await urlSession.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                Log.network.info("✅ [V5] Blocking action response: \(httpResponse.statusCode)")
            }
            
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let statusString = json[JSONKeys.status.rawValue] as? String else {
                Log.network.error("❌ [V5] Failed to parse blocking action response")
                throw PiholeServiceError.cannotParseResponse
            }

            let status = PiholeStatus(rawValue: statusString) ?? .unknown
            Log.network.info("🎯 [V5] Blocking action completed. New status: \(status.rawValue)")
            return status
        } catch {
            Log.network.error("💥 [V5] Blocking action failed: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - Data types

extension PiholeV5Service {

    private enum Endpoint {
        case summary
        case status
        case history
        case custom(String)

        var rawValue: String {
            switch self {
            case .summary:
                return "summaryRaw"
            case .status:
                return "status"
            case .history:
                return "overTimeData10mins"
            case .custom(let endpoint):
                return endpoint
            }
        }
    }


    private enum JSONKeys: String {
        case domainsBeingBlocked = "domains_being_blocked"
        case dnsQueriesToday = "dns_queries_today"
        case adsBlockedToday = "ads_blocked_today"
        case adsPercentageToday = "ads_percentage_today"
        case uniqueDomains = "unique_domains"
        case queriesForwarded = "queries_forwarded"
        case status
        case domainsOverTime = "domains_over_time"
        case adsOverTime = "ads_over_time"
        case topQueries = "top_queries"
        case topAds = "top_ads"
        case topSources = "top_sources"
        case topSourcesBlocked = "top_sources_blocked"
        case queryTypes = "querytypes"
        case forwardDestinations = "forward_destinations"
        case data
        case coreUpdate = "core_update"
        case webUpdate = "web_update"
        case ftlUpdate = "FTL_update"
        case coreCurrent = "core_current"
        case webCurrent = "web_current"
        case ftlCurrent = "FTL_current"
    }
}
