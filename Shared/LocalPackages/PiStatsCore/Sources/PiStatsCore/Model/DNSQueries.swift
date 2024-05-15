//
//  DNSQueriesOverTime.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

public protocol DNSQueries {
    var domains: [TimestampedDNSRequest] { get }
    var blocked: [TimestampedDNSRequest] { get }
}

public struct TimestampedDNSRequest: Codable {
    let timestamp: Int
    let value: Int
}


//MARK: - V5 domains over time

struct DNSQueriesOverTime: Codable, DNSQueries {
    let domains: [TimestampedDNSRequest]
    let blocked: [TimestampedDNSRequest]

    enum CodingKeys: String, CodingKey {
          case domains = "domains_over_time"
          case blocked = "ads_over_time"
      }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let domainsDict = try container.decode([String: Int].self, forKey: .domains)
        let adsDict = try container.decode([String: Int].self, forKey: .blocked)

        domains = domainsDict.map { TimestampedDNSRequest(timestamp: Int($0.key)!, value: $0.value) }
        blocked = adsDict.map { TimestampedDNSRequest(timestamp: Int($0.key)!, value: $0.value) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let domainsDict = Dictionary(uniqueKeysWithValues: domains.map { ("\($0.timestamp)", $0.value) })
        let adsDict = Dictionary(uniqueKeysWithValues: blocked.map { ("\($0.timestamp)", $0.value) })
        try container.encode(domainsDict, forKey: .domains)
        try container.encode(adsDict, forKey: .blocked)
    }
}


//MARK: - V6 History

struct HistoryResponse: Codable {
    let history: [TimestampedHistory]
}

struct TimestampedHistory: Codable {
    let timestamp: Int
    let total: Int
    let cached: Int
    let blocked: Int
}


extension HistoryResponse: DNSQueries {
    var domains: [TimestampedDNSRequest] {
        return history.map { TimestampedDNSRequest(timestamp: $0.timestamp, value: $0.total) }
    }

    var blocked: [TimestampedDNSRequest] {
        return history.map { TimestampedDNSRequest(timestamp: $0.timestamp, value: $0.blocked) }
    }
}
