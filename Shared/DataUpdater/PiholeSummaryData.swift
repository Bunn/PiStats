//
//  PiholeSummaryData.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import Combine
import Foundation
import PiStatsCore

final class PiholeSummaryData: Identifiable, ObservableObject {
    let id = UUID()

    @Published var totalQueries: String = ""
    @Published var queriesBlocked: String = ""
    @Published var percentageBlocked: String = ""
    @Published var domainsOnList: String = ""
    @Published var name: String = ""
    @Published var status: PiholeStatus = .unknown
    @Published var topDomains: TopDomainsResult? = nil
    @Published var topClients: TopClientsResult? = nil
    @Published var history: [HistoryItem]? = nil
    @Published var queryTypes: QueryTypesResult? = nil
    @Published var upstreams: UpstreamsResult? = nil
    @Published var health: PiholeHealth? = nil
    @Published var systemMetrics: PiMonitorMetrics? = nil
    @Published var currentError: PiholeError? = nil
    @Published var hasError: Bool = false
    @Published var hasPiholeError: Bool = false
}

// MARK: - Error Model

struct PiholeError: Identifiable {
    let id = UUID()
    let type: ErrorType
    let originalError: Error
    let timestamp: Date
    
    var humanReadableMessage: String {
        return type.humanReadableMessage
    }
    
    var technicalDetails: String {
        return originalError.localizedDescription
    }
    
    enum ErrorType {
        case networkError
        case authenticationError
        case invalidConfiguration
        case serverError
        case parsingError
        case systemMetricsError
        case unknown
        
        var humanReadableMessage: String {
            switch self {
            case .networkError:
                return "Unable to connect to Pi-hole. Check your network connection and Pi-hole address."
            case .authenticationError:
                return "Authentication failed. Please check your API token or password."
            case .invalidConfiguration:
                return "Pi-hole configuration is invalid. Please check your settings."
            case .serverError:
                return "Pi-hole server returned an error. The service might be temporarily unavailable."
            case .parsingError:
                return "Unable to parse response from Pi-hole. The API might have changed."
            case .systemMetricsError:
                return "Unable to fetch system metrics from Pi-hole."
            case .unknown:
                return "An unexpected error occurred."
            }
        }
    }
}

extension PiholeSummaryData {
    static var mockData: PiholeSummaryData = {
        let mock = PiholeSummaryData()
        mock.name = "Pi-hole"
        mock.totalQueries = "1000"
        mock.queriesBlocked = "200"
        mock.percentageBlocked = "20%"
        mock.domainsOnList = "1500"
        mock.status = .enabled
        return mock
    }()
}
