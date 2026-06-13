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
        NavigationStack {
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
                        onClearMessages: { await dataUpdater.clearMessages() },
                        onLoadDenyRules: dataUpdater.pihole.version == .v6 ? { try await dataUpdater.fetchDenyRegexRules() } : nil,
                        onBlockRules: dataUpdater.pihole.version == .v6 ? { rules in try await dataUpdater.addDenyRegexRules(rules) } : nil,
                        onUnblockRules: dataUpdater.pihole.version == .v6 ? { rules in try await dataUpdater.removeDenyRegexRules(rules) } : nil
                    )

                    if dataUpdater.pihole.version == .v6 {
                        blocklistsCard
                    }
                }
                .padding()
            }
            .navigationTitle(summary.name)
        }
    }

    private var blocklistsCard: some View {
        NavigationLink {
            AdListsView(load: { try await dataUpdater.fetchAdlists() },
                        toggle: { list, enabled in try await dataUpdater.setAdlist(list, enabled: enabled) },
                        updateGravity: { try await dataUpdater.updateGravity() },
                        gravityLastUpdated: { try await dataUpdater.fetchGravityLastUpdated() })
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.blocklistsCardTitle)
                        .font(.headline)
                    Text(UserText.blocklistsCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
