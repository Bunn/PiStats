//
//  PiholeDetailContentView.swift
//  PiStats
//
//  The full, detailed set of sections for a single Pi-hole: complete stats,
//  the query-history chart, top domains, top clients and device metrics.
//  Shared by the iOS detail screen and the macOS main window so both surfaces
//  stay in sync.
//

import SwiftUI
import PiStatsCore

struct PiholeDetailContentView: View {
    @ObservedObject var data: PiholeSummaryData
    let temperatureScale: TemperatureScale
    var showsStats: Bool = true
    var showsMetrics: Bool = true
    var displayStatsAsList: Bool = true
    var onClearMessages: (() async -> Void)? = nil
    /// Supplied only for Pi-hole v6 (where service blocking is supported).
    var onLoadDenyRules: (() async throws -> [String])? = nil
    var onBlockRules: (([String]) async throws -> Void)? = nil
    var onUnblockRules: (([String]) async throws -> Void)? = nil
    /// Supplied only for Pi-hole v6: adds a domain to an allow/deny list from
    /// the Top Domains context menu.
    var onQuickAddDomain: ((DomainRule) async -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let health = data.health {
                section(UserText.healthSection) {
                    HealthView(health: health, onClear: onClearMessages)
                }
            }

            if showsStats {
                if displayStatsAsList {
                    ListView(data: data)
                } else {
                    CardViewGrid(data: data)
                }
            }

            if let history = data.history, !history.isEmpty {
                section(UserText.queryHistory) {
                    QueryHistoryChartView(items: history,
                                          permittedColor: AppColors.statusOnline,
                                          blockedColor: AppColors.queriesBlocked)
                        .frame(height: 160)
                }
            }

            if let queryTypes = data.queryTypes, !queryTypes.types.isEmpty {
                section(UserText.queryTypesSection) {
                    QueryTypesView(result: queryTypes)
                }
            }

            if let upstreams = data.upstreams, !upstreams.upstreams.isEmpty {
                section(UserText.upstreamsSection) {
                    UpstreamsView(result: upstreams)
                }
            }

            if let topDomains = data.topDomains {
                section(UserText.topDomainsSection) {
                    TopDomainsView(topDomains: topDomains, onAddDomain: onQuickAddDomain)
                }
            }

            if let topClients = data.topClients {
                section(UserText.topClientsSection) {
                    TopClientsView(topClients: topClients)
                }
            }

            if let onLoadDenyRules, let onBlockRules, let onUnblockRules {
                section(UserText.blockServicesSection) {
                    BlockServicesView(loadRules: onLoadDenyRules, block: onBlockRules, unblock: onUnblockRules)
                }
            }

            if showsMetrics, let metrics = data.monitorMetrics {
                section(UserText.deviceSection) {
                    MetricsView(viewModel: .init(metrics: metrics, temperatureScale: temperatureScale))
                        .contentTransition(.numericText())
                }
            }
        }
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .modifier(DetailSectionCardStyle())
    }
}

// MARK: - Section Card Style

/// A titled card background for detail sections: Liquid Glass on iOS,
/// a material-style stroked card on macOS.
private struct DetailSectionCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        content
            .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
        #else
        content
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            )
        #endif
    }
}

#Preview {
    ScrollView {
        PiholeDetailContentView(data: .mockData, temperatureScale: .celsius)
            .padding()
    }
}
