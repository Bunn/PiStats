//
//  AppIntent.swift
//  PiStatsWidget
//
//  Created by Fernando Bunn on 29/06/2025.
//

import WidgetKit
import AppIntents
import PiStatsCore
import Foundation

// MARK: - Pihole Selection Intent

struct PiholeSelectionIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Pi-hole" }
    static var description = IntentDescription("Choose which Pi-hole to display in the widget")
    
    @Parameter(title: "Pi-hole", default: nil)
    var pihole: PiholeEntity?
}

// MARK: - Pihole Entity

struct PiholeEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Pi-hole"
    static var defaultQuery = PiholeQuery()
    
    let id: String
    let name: String
    let address: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
    
    init(pihole: Pihole) {
        self.id = pihole.uuid.uuidString
        self.name = pihole.name
        self.address = pihole.address
    }
}

// MARK: - Pihole Query

struct PiholeQuery: EntityQuery {
    func entities(for identifiers: [PiholeEntity.ID]) async throws -> [PiholeEntity] {
        let allPiholes = widgetPiholeStorage.restoreAllPiholes()
        return allPiholes.compactMap { pihole in
            if identifiers.contains(pihole.uuid.uuidString) {
                return PiholeEntity(pihole: pihole)
            }
            return nil
        }
    }
    
    func suggestedEntities() async throws -> [PiholeEntity] {
        let allPiholes = widgetPiholeStorage.restoreAllPiholes()
        Log.widget.info("Found \(allPiholes.count, privacy: .public) piholes in storage")
        return allPiholes.map { PiholeEntity(pihole: $0) }
    }
    
    func defaultResult() async -> PiholeEntity? {
        let allPiholes = widgetPiholeStorage.restoreAllPiholes()
        return allPiholes.first.map { PiholeEntity(pihole: $0) }
    }
}

// MARK: - Widget Data Structures

struct PiStatsEntry: TimelineEntry {
    let date: Date
    let widgetData: WidgetData?
    
    static func placeholder() -> PiStatsEntry {
        let mockPihole = Pihole(
            name: "Home Pi-hole",
            address: "192.168.1.100",
            version: .v6,
            port: 80,
            token: "sample_token"
        )
        
        let mockSummary = PiholeSummary(
            domainsBeingBlocked: 125000,
            queries: 54832,
            adsBlocked: 12543,
            adsPercentageToday: 22.9,
            uniqueDomains: 2840,
            queriesForwarded: 42289
        )
        
        let mockMetrics = PiMonitorMetrics(
            socTemperature: 65.2,
            uptime: 432000, // 5 days
            loadAverage: [0.8, 0.7, 0.9],
            kernelRelease: "6.1.21-v8+",
            memory: PiMonitorMetrics.Memory(
                totalMemory: 4000000000, // 4GB
                freeMemory: 800000000, // 800MB free
                availableMemory: 1500000000 // 1.5GB available
            )
        )
        
        let widgetData = WidgetData(
            pihole: mockPihole,
            summary: mockSummary,
            status: .enabled,
            monitorMetrics: mockMetrics,
            error: nil
        )
        
        return PiStatsEntry(date: Date(), widgetData: widgetData)
    }
}

struct WidgetData {
    let pihole: Pihole
    let summary: PiholeSummary?
    let status: PiholeStatus
    let monitorMetrics: PiMonitorMetrics?
    let error: String?
}

// MARK: - Widget Data Provider

struct WidgetDataProvider {
    typealias Entry = PiStatsEntry
    
    private func fetchWidgetData(for pihole: Pihole) async -> WidgetData {
        Log.widget.info("Fetching data for pihole \(pihole.name, privacy: .private(mask: .hash))")
        
        do {
            let client = PiholeAPIClient(pihole)
            
            // Fetch status and summary in parallel with simpler approach
            async let statusTask = client.fetchStatus()
            async let summaryTask = client.fetchSummary()
            
            let status = try await statusTask
            let summary = try await summaryTask
            
            // Fetch monitor metrics if available (with shorter timeout)
            var monitorMetrics: PiMonitorMetrics? = nil
            if let piMonitor = pihole.piMonitor {
                do {
                    let monitor = PiMonitor(
                        host: piMonitor.host,
                        port: piMonitor.port,
                        timeoutInterval: 8,
                        secure: piMonitor.secure
                    )
                    monitorMetrics = try await monitor.fetchMetrics()
                } catch {
                    Log.widget.error("Failed to fetch Pi Monitor metrics: \(String(describing: error), privacy: .public)")
                }
            }
            
            Log.widget.info("Successfully fetched data for pihole \(pihole.name, privacy: .private(mask: .hash))")
            return WidgetData(
                pihole: pihole,
                summary: summary,
                status: status,
                monitorMetrics: monitorMetrics,
                error: nil
            )
            
        } catch {
            Log.widget.error("Failed to fetch data for pihole \(pihole.name, privacy: .private(mask: .hash)): \(String(describing: error), privacy: .public)")
            return WidgetData(
                pihole: pihole,
                summary: nil,
                status: .unknown,
                monitorMetrics: nil,
                error: error.localizedDescription
            )
        }
    }
    
    private struct TimeoutError: Error {}
}


// MARK: - Timeline Provider Implementation

extension WidgetDataProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> PiStatsEntry {
        return PiStatsEntry.placeholder()
    }
    
    func snapshot(for configuration: PiholeSelectionIntent, in context: Context) async -> PiStatsEntry {
        // For snapshots (widget configuration), return placeholder data quickly
        if context.isPreview {
            return PiStatsEntry.placeholder()
        }
        
        if let piholeEntity = configuration.pihole,
           let uuid = UUID(uuidString: piholeEntity.id),
           let pihole = widgetPiholeStorage.restorePihole(uuid) {
            // For configuration, just return a basic entry without fetching data
            let basicData = WidgetData(
                pihole: pihole,
                summary: nil,
                status: .unknown,
                monitorMetrics: nil,
                error: nil
            )
            return PiStatsEntry(date: Date(), widgetData: basicData)
        } else {
            // No pihole selected, return empty state
            return PiStatsEntry(date: Date(), widgetData: nil)
        }
    }
    
    func timeline(for configuration: PiholeSelectionIntent, in context: Context) async -> Timeline<PiStatsEntry> {
        let currentDate = Date()
        
        if let piholeEntity = configuration.pihole,
           let uuid = UUID(uuidString: piholeEntity.id),
           let pihole = widgetPiholeStorage.restorePihole(uuid) {
            
            // Only fetch data once for the current entry to avoid long loading times
            let widgetData = await fetchWidgetData(for: pihole)
            let entry = PiStatsEntry(date: currentDate, widgetData: widgetData)
            
            // Refresh again in 15 minutes
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            return Timeline(entries: [entry], policy: .after(nextRefresh))
        } else {
            // No pihole selected, show empty state
            let entry = PiStatsEntry(date: currentDate, widgetData: nil)
            // Refresh in 5 minutes to check if user has configured a pihole
            let nextRefresh = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
            return Timeline(entries: [entry], policy: .after(nextRefresh))
        }
    }
}

// MARK: - Widget Storage

/// Widget-specific PiholeStorage instance for accessing Pi-hole data from widgets
let widgetPiholeStorage: PiholeStorage = widgetStorage
