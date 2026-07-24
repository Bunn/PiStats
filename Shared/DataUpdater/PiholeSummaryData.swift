//
//  PiholeSummaryData.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import Combine
import Foundation
import PiStatsCore

@MainActor
final class PiholeSummaryData: Identifiable, ObservableObject {
    let id = UUID()

    @Published var totalQueries: String = "—"
    @Published var queriesBlocked: String = "—"
    @Published var percentageBlocked: String = "—"
    @Published var domainsOnList: String = "—"
    @Published var name: String = ""
    @Published var status: PiholeStatus = .unknown
    @Published var topDomains: TopDomainsResult? = nil
    @Published var topClients: TopClientsResult? = nil
    @Published var history: [HistoryItem]? = nil
    @Published var queryTypes: QueryTypesResult? = nil
    @Published var upstreams: UpstreamsResult? = nil
    @Published var health: PiholeHealth? = nil
    @Published var systemMetrics: PiholeSystemMetrics? = nil
    @Published var currentError: PiholeError? = nil
    @Published var hasError: Bool = false
    @Published var hasPiholeError: Bool = false
    @Published var connectionState: PiholeConnectionState = .idle
    @Published var isRefreshing = false
    @Published var hasLoadedSummary = false
    @Published var hasLoadedStatus = false
    @Published var lastSuccessfulRefresh: Date?

    var hasPrimaryData: Bool {
        hasLoadedSummary || hasLoadedStatus
    }

    init() {}

    init(copying source: PiholeSummaryData, name: String) {
        totalQueries = source.totalQueries
        queriesBlocked = source.queriesBlocked
        percentageBlocked = source.percentageBlocked
        domainsOnList = source.domainsOnList
        self.name = name
        status = source.status
        topDomains = source.topDomains
        topClients = source.topClients
        history = source.history
        queryTypes = source.queryTypes
        upstreams = source.upstreams
        health = source.health
        systemMetrics = source.systemMetrics
        hasLoadedSummary = source.hasLoadedSummary
        hasLoadedStatus = source.hasLoadedStatus
        lastSuccessfulRefresh = source.lastSuccessfulRefresh
        connectionState = source.hasPrimaryData ? .stale : .idle
    }
}

// MARK: - Error Model

struct PiholeError: Identifiable, Sendable {
    let id = UUID()
    let type: ErrorType
    let technicalDetails: String
    let timestamp: Date

    init(type: ErrorType, originalError: Error, timestamp: Date) {
        self.type = type
        self.technicalDetails = originalError.localizedDescription
        self.timestamp = timestamp
    }
    
    var humanReadableMessage: String {
        type.humanReadableMessage
    }
    
    enum ErrorType: Sendable {
        case networkError
        case authenticationError
        case invalidConfiguration
        case serverError
        case parsingError
        case systemMetricsError
        case unknown

        var isTransient: Bool {
            switch self {
            case .networkError, .serverError, .unknown:
                true
            case .authenticationError, .invalidConfiguration, .parsingError, .systemMetricsError:
                false
            }
        }
        
        var humanReadableMessage: String {
            switch self {
            case .networkError:
                return "Unable to connect to Pi-hole. Check your network connection and Pi-hole address."
            case .authenticationError:
                return "Authentication failed. Please check your Pi-hole password."
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
    static let mockData: PiholeSummaryData = {
        let mock = PiholeSummaryData()
        mock.name = "Pi-hole"
        mock.totalQueries = "1000"
        mock.queriesBlocked = "200"
        mock.percentageBlocked = "20%"
        mock.domainsOnList = "1500"
        mock.status = .enabled
        mock.connectionState = .connected
        mock.hasLoadedSummary = true
        mock.hasLoadedStatus = true
        return mock
    }()
}
