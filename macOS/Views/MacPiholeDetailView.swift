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
    @State private var toast: String?
    @State private var actionError: String?

    private var isV6: Bool { dataUpdater.pihole.version == .v6 }

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
                        onLoadDenyRules: isV6 ? { try await dataUpdater.fetchDomains(type: .deny, kind: .regex).map(\.domain) } : nil,
                        onBlockRules: isV6 ? { rules in try await dataUpdater.addDomains(rules.map { DomainRule(domain: $0, type: .deny, kind: .regex, comment: "Blocked by PiStats") }) } : nil,
                        onUnblockRules: isV6 ? { rules in try await dataUpdater.removeDomains(rules.map { DomainRule(domain: $0, type: .deny, kind: .regex) }) } : nil,
                        onQuickAddDomain: isV6 ? { rule in await quickAdd(rule) } : nil
                    )

                    if isV6 {
                        blocklistsCard
                        domainsCard
                    }
                }
                .padding()
            }
            .navigationTitle(summary.name)
            .domainActionToast($toast)
            .alert("Couldn't update list", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
                Button("OK", role: .cancel) { actionError = nil }
            } message: {
                Text(actionError ?? "")
            }
        }
    }

    private func quickAdd(_ rule: DomainRule) async {
        do {
            try await dataUpdater.addDomains([rule])
            toast = rule.type == .allow ? UserText.domainAddedToAllow(rule.domain) : UserText.domainAddedToBlock(rule.domain)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private var domainActions: DomainManagementActions {
        DomainManagementActions(
            loadAll: { try await dataUpdater.fetchAllDomains() },
            add: { try await dataUpdater.addDomains($0) },
            remove: { try await dataUpdater.removeDomains($0) },
            setEnabled: { rule, enabled in try await dataUpdater.setDomain(rule, enabled: enabled) }
        )
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

    private var domainsCard: some View {
        NavigationLink {
            DomainListView(actions: domainActions)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.domainsCardTitle)
                        .font(.headline)
                    Text(UserText.domainsCardSubtitle)
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
