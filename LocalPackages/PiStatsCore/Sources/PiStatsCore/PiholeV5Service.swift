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
        guard let url = URL(string: "http://\(pihole.address)/admin/api.php?\(endpoint.rawValue)&auth=\(pihole.token ?? "")") else {
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

        var urlComponents = URLComponents(string: "http://\(pihole.address)/admin/api.php")!
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
    }
}
