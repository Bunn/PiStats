//
//  MacPiholeDetailView.swift
//  macOS
//
//  A standalone window showing the full detail for a single Pi-hole,
//  opened from the menu-bar popover's "More Details". Mirrors the iOS
//  pushed detail screen.
//

import SwiftUI
import PiStatsCore

/// Resolves the live data updater for a Pi-hole id and renders its detail.
struct MacPiholeDetailWindow: View {
    @ObservedObject var dataManager: PiholeDataManager
    @ObservedObject var prefs: MacPreferences
    let piholeID: UUID?

    var body: some View {
        Group {
            if let updater = resolveUpdater() {
                MacPiholeDetailView(dataUpdater: updater, summary: updater.summary, prefs: prefs)
            } else {
                ContentUnavailableView(UserText.Popover.noPiholesTitle,
                                       systemImage: SystemImages.shieldSlash)
            }
        }
        .frame(minWidth: 360, idealWidth: 440, minHeight: 420)
    }

    private func resolveUpdater() -> PiholeSummaryDataUpdater? {
        guard let piholeID else { return nil }
        return dataManager.listUpdater?.dataUpdaters.first { $0.pihole.uuid == piholeID }
    }
}

struct MacPiholeDetailView: View {
    @ObservedObject var dataUpdater: PiholeSummaryDataUpdater
    @ObservedObject var summary: PiholeSummaryData
    @ObservedObject var prefs: MacPreferences

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    StatusHeaderView(data: summary)
                    Spacer()
                    ActionButtonView(
                        status: summary.status,
                        prefs: prefs,
                        onEnable: { await dataUpdater.enable() },
                        onDisable: { timer in await dataUpdater.disable(timer: timer) }
                    )
                }

                if summary.hasError, let error = summary.currentError {
                    ErrorMessageView(error: error, isCollapsible: false)
                }

                PiholeDetailContentView(
                    data: summary,
                    temperatureScale: prefs.temperatureScale,
                    showsStats: true,
                    showsMetrics: true,
                    displayStatsAsList: true,
                    onClearMessages: { await dataUpdater.clearMessages() }
                )
            }
            .padding()
        }
        .navigationTitle(summary.name)
    }
}
