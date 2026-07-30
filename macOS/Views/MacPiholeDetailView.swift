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
            if let listUpdater = dataManager.listUpdater,
               let updater = resolveUpdater(in: listUpdater) {
                MacPiholeDetailView(
                    dataUpdater: updater,
                    listUpdater: listUpdater,
                    summary: updater.summary,
                    prefs: prefs
                )
            } else {
                ContentUnavailableView(UserText.Popover.noPiholesTitle,
                                       systemImage: SystemImages.shieldSlash)
            }
        }
        .frame(minWidth: 360, idealWidth: 440, minHeight: 420)
    }

    private func resolveUpdater(in listUpdater: PiholeListUpdater) -> PiholeSummaryDataUpdater? {
        guard let piholeID else { return nil }
        return listUpdater.dataUpdaters.first { $0.pihole.uuid == piholeID }
    }
}

struct MacPiholeDetailView: View {
    @ObservedObject var dataUpdater: PiholeSummaryDataUpdater
    @ObservedObject var listUpdater: PiholeListUpdater
    @ObservedObject var summary: PiholeSummaryData
    @ObservedObject var prefs: MacPreferences
    @State private var toast: String?
    @State private var actionError: String?

    private var configurationSyncOptions: PiholeConfigurationSyncOptions {
        PiholeConfigurationSyncOptions(
            configuredPiholeCount: listUpdater.dataUpdaters.count,
            automaticallySyncsChanges: prefs.syncConfigurationChanges
        )
    }

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
                        configurationSyncOptions: configurationSyncOptions,
                        onClearMessages: { await dataUpdater.clearMessages() },
                        onLoadDenyRules: { try await dataUpdater.fetchDomains(type: .deny, kind: .regex).map(\.domain) },
                        onBlockRules: { rules, scope in
                            try await listUpdater.addDomains(
                                rules.map {
                                    DomainRule(
                                        domain: $0,
                                        type: .deny,
                                        kind: .regex,
                                        comment: "Blocked by PiStats"
                                    )
                                },
                                from: dataUpdater,
                                scope: scope
                            )
                        },
                        onUnblockRules: { rules, scope in
                            try await listUpdater.removeDomains(
                                rules.map {
                                    DomainRule(domain: $0, type: .deny, kind: .regex)
                                },
                                from: dataUpdater,
                                scope: scope
                            )
                        },
                        onQuickAddDomain: { rule, scope in
                            await quickAdd(rule, scope: scope)
                        }
                    )

                    blocklistsCard
                    domainsCard
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

    private func quickAdd(
        _ rule: DomainRule,
        scope: PiholeConfigurationChangeScope
    ) async {
        do {
            try await listUpdater.addDomains(
                [rule],
                from: dataUpdater,
                scope: scope
            )
            toast = rule.type == .allow ? UserText.domainAddedToAllow(rule.domain) : UserText.domainAddedToBlock(rule.domain)
        } catch {
            if (error as? PiholeConfigurationSyncError)?.currentPiholeWasUpdated == true {
                toast = rule.type == .allow ? UserText.domainAddedToAllow(rule.domain) : UserText.domainAddedToBlock(rule.domain)
            }
            actionError = error.localizedDescription
        }
    }

    private var domainActions: DomainManagementActions {
        DomainManagementActions(
            syncOptions: configurationSyncOptions,
            loadAll: { try await dataUpdater.fetchAllDomains() },
            add: { rules, scope in
                try await listUpdater.addDomains(
                    rules,
                    from: dataUpdater,
                    scope: scope
                )
            },
            remove: { rules, scope in
                try await listUpdater.removeDomains(
                    rules,
                    from: dataUpdater,
                    scope: scope
                )
            },
            setEnabled: { rule, enabled, scope in
                try await listUpdater.setDomain(
                    rule,
                    enabled: enabled,
                    from: dataUpdater,
                    scope: scope
                )
            }
        )
    }

    private var blocklistsCard: some View {
        NavigationLink {
            AdListsView(
                syncOptions: configurationSyncOptions,
                load: { try await dataUpdater.fetchAdlists() },
                toggle: { list, enabled, scope in
                    try await listUpdater.setAdlist(
                        list,
                        enabled: enabled,
                        from: dataUpdater,
                        scope: scope
                    )
                },
                updateGravity: { try await dataUpdater.updateGravity() },
                gravityLastUpdated: { try await dataUpdater.fetchGravityLastUpdated() }
            )
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
