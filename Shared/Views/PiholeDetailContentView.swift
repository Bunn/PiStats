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

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            if let topDomains = data.topDomains {
                section(UserText.topDomainsSection) {
                    TopDomainsView(topDomains: topDomains)
                }
            }

            if let topClients = data.topClients {
                section(UserText.topClientsSection) {
                    TopClientsView(topClients: topClients)
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ScrollView {
        PiholeDetailContentView(data: .mockData, temperatureScale: .celsius)
            .padding()
    }
}
