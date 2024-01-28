//
//  Summary.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

public protocol Summary {
    var totalQueries: Int { get }
    var queriesBlocked: Int { get }
    var percentBlocked: Double { get }
    var domainsOnList: Int { get }
    var activeClients: Int { get }
}


// MARK: - Summary for Pi-hole V6 or higher

public struct SummaryV6: Summary, Decodable {
    struct Queries: Codable {
        let total: Int
        let blocked: Int
        let percent_blocked: Double
        let unique_domains: Int
        let forwarded: Int
        let cached: Int
    }

    struct Clients: Codable {
        let active: Int
        let total: Int
    }

    struct Gravity: Codable {
        let domains_being_blocked: Int
    }

    let queries: Queries
    let clients: Clients
    let gravity: Gravity

    // Summary conformance
    public var totalQueries: Int { queries.total }
    public var queriesBlocked: Int { queries.blocked }
    public var percentBlocked: Double { queries.percent_blocked }
    public var domainsOnList: Int { gravity.domains_being_blocked }
    public var activeClients: Int { clients.active }
}


// MARK: - Summary for Pi-hole V5 or lower

struct SummaryV5: Summary, Decodable {
    let domains_being_blocked: Int
    let dns_queries_today: Int
    let ads_blocked_today: Int
    let ads_percentage_today: Double
    let unique_clients: Int
    let status: String

    // Summary conformance
    public var totalQueries: Int { dns_queries_today }
    public var queriesBlocked: Int { ads_blocked_today }
    public var percentBlocked: Double { ads_percentage_today }
    public var domainsOnList: Int { domains_being_blocked }
    public var activeClients: Int { unique_clients }
}
