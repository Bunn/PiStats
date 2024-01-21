//
//  Summary.swift
//
//
//  Created by Fernando Bunn on 25/04/2020.
//

import Foundation

public struct Summary: Decodable {
    public let domainsBeingBlocked, dnsQueriesToday, adsBlockedToday: Int
    public let adsPercentageToday: Double
    public let uniqueDomains, queriesForwarded, queriesCached, clientsEverSeen: Int
    public let uniqueClients, dnsQueriesAllTypes, replyNODATA, replyNXDOMAIN: Int
    public let replyCNAME, replyIP, privacyLevel: Int
    public let status: String
    public let gravityLastUpdated: GravityLastUpdated

    enum CodingKeys: String, CodingKey {
        case domainsBeingBlocked = "domains_being_blocked"
        case dnsQueriesToday = "dns_queries_today"
        case adsBlockedToday = "ads_blocked_today"
        case adsPercentageToday = "ads_percentage_today"
        case uniqueDomains = "unique_domains"
        case queriesForwarded = "queries_forwarded"
        case queriesCached = "queries_cached"
        case clientsEverSeen = "clients_ever_seen"
        case uniqueClients = "unique_clients"
        case dnsQueriesAllTypes = "dns_queries_all_types"
        case replyNODATA = "reply_NODATA"
        case replyNXDOMAIN = "reply_NXDOMAIN"
        case replyCNAME = "reply_CNAME"
        case replyIP = "reply_IP"
        case privacyLevel = "privacy_level"
        case status
        case gravityLastUpdated = "gravity_last_updated"
    }
}


// MARK: - GravityLastUpdated

public struct GravityLastUpdated: Decodable {
    public let fileExists: Bool
    public let absolute: Int
    public let relative: Relative

    enum CodingKeys: String, CodingKey {
        case fileExists = "file_exists"
        case absolute, relative
    }
}


// MARK: - Relative

public struct Relative: Decodable {
    public var days, hours, minutes: Int

    enum CodingKeys: String, CodingKey {
          case days
          case hours
          case minutes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        /*
         Pi-hole 4.x used Strings for these values
         whereas 5.x uses Int, so we try to decode both
         */
        do {
            days = Int(try values.decode(String.self, forKey: .days)) ?? 0
            hours = Int(try values.decode(String.self, forKey: .hours)) ?? 0
            minutes = Int(try values.decode(String.self, forKey: .minutes)) ?? 0
        } catch {
            days = try values.decode(Int.self, forKey: .days)
            hours = try values.decode(Int.self, forKey: .hours)
            minutes = try values.decode(Int.self, forKey: .minutes)
        }
    }
}




struct SummaryV6: Codable {
    struct Queries: Codable {
        let total: Int
        let blocked: Int
        let percent_blocked: Double
        let unique_domains: Int
        let forwarded: Int
        let cached: Int
        struct Types: Codable {
            let A: Int
            let AAAA: Int
            let ANY: Int
            let SRV: Int
            let SOA: Int
            let PTR: Int
            let TXT: Int
            let NAPTR: Int
            let MX: Int
            let DS: Int
            let RRSIG: Int
            let DNSKEY: Int
            let NS: Int
            let SVCB: Int
            let HTTPS: Int
            let OTHER: Int
        }
        let types: Types
        struct Status: Codable {
            let UNKNOWN: Int
            let GRAVITY: Int
            let FORWARDED: Int
            let CACHE: Int
            let REGEX: Int
            let DENYLIST: Int
            let EXTERNAL_BLOCKED_IP: Int
            let EXTERNAL_BLOCKED_NULL: Int
            let EXTERNAL_BLOCKED_NXRA: Int
            let GRAVITY_CNAME: Int
            let REGEX_CNAME: Int
            let DENYLIST_CNAME: Int
            let RETRIED: Int
            let RETRIED_DNSSEC: Int
            let IN_PROGRESS: Int
            let DBBUSY: Int
            let SPECIAL_DOMAIN: Int
            let CACHE_STALE: Int
        }
        let status: Status
        struct Replies: Codable {
            let UNKNOWN: Int
            let NODATA: Int
            let NXDOMAIN: Int
            let CNAME: Int
            let IP: Int
            let DOMAIN: Int
            let RRNAME: Int
            let SERVFAIL: Int
            let REFUSED: Int
            let NOTIMP: Int
            let OTHER: Int
            let DNSSEC: Int
            let NONE: Int
            let BLOB: Int
        }
        let replies: Replies
    }
    let queries: Queries
    struct Clients: Codable {
        let active: Int
        let total: Int
    }
    let clients: Clients
    struct Gravity: Codable {
        let domains_being_blocked: Int
    }
    let gravity: Gravity
    let took: Double
}

struct SummaryV5: Codable {
    let domains_being_blocked: Int
    let dns_queries_today: Int
    let ads_blocked_today: Int
    let ads_percentage_today: Double
    let unique_domains: Int
    let queries_forwarded: Int
    let queries_cached: Int
    let clients_ever_seen: Int
    let unique_clients: Int
    let dns_queries_all_types: Int
    let reply_UNKNOWN: Int
    let reply_NODATA: Int
    let reply_NXDOMAIN: Int
    let reply_CNAME: Int
    let reply_IP: Int
    let reply_DOMAIN: Int
    let reply_RRNAME: Int
    let reply_SERVFAIL: Int
    let reply_REFUSED: Int
    let reply_NOTIMP: Int
    let reply_OTHER: Int
    let reply_DNSSEC: Int
    let reply_NONE: Int
    let reply_BLOB: Int
    let dns_queries_all_replies: Int
    let privacy_level: Int
    let status: String
    struct GravityLastUpdated: Codable {
        let file_exists: Bool
        let absolute: Int
        struct Relative: Codable {
            let days: Int
            let hours: Int
            let minutes: Int
        }
        let relative: Relative
    }
    let gravity_last_updated: GravityLastUpdated
    let top_queries: [String: Int]
    let top_ads: [String: Int]
    let top_sources_blocked: [String: Int]
}
