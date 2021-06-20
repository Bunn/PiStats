//
//  SummaryItemType.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI

enum SummaryItemType {
    case totalQuery
    case queryBlocked
    case percentBlocked
    case domainsOnBlocklist
    
    var name: String {
        switch self {
        case .totalQuery:
            return "Total Queries"
        case .domainsOnBlocklist:
            return "Domains on Blocklist"
        case .percentBlocked:
            return "Percent Blocked"
        case .queryBlocked:
            return "Queries Blocked"
        
        }
    }
    
    var color: Color {
        switch self {
        case .totalQuery:
            return Color("totalQuery")
        case .domainsOnBlocklist:
            return Color("domainBlocked")
        case .percentBlocked:
            return Color("percentBlocked")
        case .queryBlocked:
            return Color("queryBlocked")
        }
    }
}
