//
//  PiStatsCardView.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//
import SwiftUI
import PiStatsCore

struct PiStatsCardView: View {
    @ObservedObject var data: PiholeSummaryData
    let updater: PiholeSummaryDataUpdater
    @ObservedObject var listUpdater: PiholeListUpdater
    @ObservedObject var settingsStore: SettingsStore
    var onSettings: () -> Void = {}
    @State private var showingDisableActionSheet = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatusHeaderView(data: data)
                Spacer()
            }

            if data.hasError, let error = data.currentError {
                ErrorMessageView(error: error)
            }

            if settingsStore.displayStatsAsList {
                ListView(data: data)
            } else {
                CardViewGrid(data: data)
            }

            if let metrics = data.systemMetrics {
                Divider()
                MetricsView(viewModel: .init(metrics: metrics, temperatureScale: settingsStore.temperatureScale))
                    .contentTransition(.numericText())
            }

            actionButtons

            toggleButton()
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
        .actionSheet(isPresented: $showingDisableActionSheet) {
            ActionSheet(
                title: Text(UserText.disablePiholeOptionsTitle),
                buttons: createDisableActionButtons()
            )
        }
    }
}

#Preview {
    let updater = PiholeSummaryDataUpdater(pihole: .init(name: "Test", address: "1234"))
    let listUpdater = PiholeListUpdater(dataUpdaters: [updater])

    NavigationStack {
        PiStatsCardView(
            data: .mockData,
            updater: updater,
            listUpdater: listUpdater,
            settingsStore: SettingsStore()
        )
            .padding()
    }
}

extension PiStatsCardView {
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onSettings) {
                Label(UserText.settingsButton, systemImage: SystemImages.gearshape)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
            }
            .buttonStyle(.plain)

            NavigationLink {
                PiholeDetailView(
                    data: data,
                    updater: updater,
                    listUpdater: listUpdater,
                    settingsStore: settingsStore
                )
            } label: {
                Label(UserText.moreDetails, systemImage: SystemImages.moreDetails)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleButton() -> some View {
        if data.status == .disabled {
            return AnyView(enableButton())
        } else if data.status == .enabled {
            return AnyView(disableButton())
        } else {
            return AnyView(EmptyView())
        }
    }

    private func disableButton() -> some View {
        Button {
            if settingsStore.disablePermanently {
                Task {
                    await updater.disable()
                    await DisableActivityController().end()
                }
            } else {
                showingDisableActionSheet = true
            }
        } label: {
            HStack(spacing: 0) {
                Label(UserText.disableButton, systemImage: SystemImages.disablePiholeButton)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .glassEffect(.regular.tint(AppColors.statusOffline).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))

        }
    }

    private func enableButton() -> some View {
        Button {
            Task {
                await updater.enable()
                await DisableActivityController().end()
            }
        } label: {
            HStack(spacing: 0) {
                Label(UserText.enableButton, systemImage: SystemImages.enablePiholeButton)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .glassEffect(.regular.tint(AppColors.totalQueries).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
        }
    }

    private func createDisableActionButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        for disableTime in settingsStore.customDisableTimes {
            buttons.append(.default(Text(disableTime.displayName)) {
                Task {
                    await updater.disable(timer: disableTime.seconds)
                    DisableActivityController().start(until: Date().addingTimeInterval(TimeInterval(disableTime.seconds)))
                }
            })
        }

        buttons.append(.destructive(Text(UserText.disablePiholeOptionsPermanently)) {
            Task {
                await updater.disable()
                await DisableActivityController().end()
            }
        })
        
        buttons.append(.cancel())

        return buttons
    }
}

// MARK: - Detail Screen

struct PiholeDetailView: View {
    @ObservedObject var data: PiholeSummaryData
    let updater: PiholeSummaryDataUpdater
    @ObservedObject var listUpdater: PiholeListUpdater
    @ObservedObject var settingsStore: SettingsStore
    @State private var toast: String?
    @State private var actionError: String?

    private var isAppStoreScreenshotMode: Bool {
#if DEBUG
        AppStoreScreenshotData.isEnabled
#else
        false
#endif
    }

    private var configurationSyncOptions: PiholeConfigurationSyncOptions {
        PiholeConfigurationSyncOptions(
            configuredPiholeCount: listUpdater.dataUpdaters.count,
            automaticallySyncsChanges: settingsStore.syncConfigurationChanges
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PiholeDetailContentView(
                    data: data,
                    temperatureScale: settingsStore.temperatureScale,
                    showsStats: false,
                    showsMetrics: false,
                    configurationSyncOptions: configurationSyncOptions,
                    onClearMessages: { await updater.clearMessages() },
                    onLoadDenyRules: {
                        if isAppStoreScreenshotMode { return [] }
                        return try await updater.fetchDomains(type: .deny, kind: .regex).map(\.domain)
                    },
                    onBlockRules: { rules, scope in
                        guard !isAppStoreScreenshotMode else { return }
                        try await listUpdater.addDomains(
                            rules.map {
                                DomainRule(
                                    domain: $0,
                                    type: .deny,
                                    kind: .regex,
                                    comment: "Blocked by PiStats"
                                )
                            },
                            from: updater,
                            scope: scope
                        )
                    },
                    onUnblockRules: { rules, scope in
                        guard !isAppStoreScreenshotMode else { return }
                        try await listUpdater.removeDomains(
                            rules.map {
                                DomainRule(domain: $0, type: .deny, kind: .regex)
                            },
                            from: updater,
                            scope: scope
                        )
                    },
                    onQuickAddDomain: { rule, scope in
                        await quickAdd(rule, scope: scope)
                    }
                )
                blocklistsCard
                domainsCard
                queryLogCard
            }
            .padding()
        }
        .navigationTitle(data.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        .domainActionToast($toast)
        .alert("Couldn't update list", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private func quickAdd(
        _ rule: DomainRule,
        scope: PiholeConfigurationChangeScope
    ) async {
        do {
            try await listUpdater.addDomains([rule], from: updater, scope: scope)
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
            loadAll: { try await updater.fetchAllDomains() },
            add: { rules, scope in
                try await listUpdater.addDomains(rules, from: updater, scope: scope)
            },
            remove: { rules, scope in
                try await listUpdater.removeDomains(rules, from: updater, scope: scope)
            },
            setEnabled: { rule, enabled, scope in
                try await listUpdater.setDomain(
                    rule,
                    enabled: enabled,
                    from: updater,
                    scope: scope
                )
            }
        )
    }

    private var queryLogCard: some View {
        NavigationLink {
            QueryLogView(
                updater: updater,
                listUpdater: listUpdater,
                syncOptions: configurationSyncOptions
            )
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.queryLogCardTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(UserText.queryLogCardSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var blocklistsCard: some View {
        NavigationLink {
            AdListsView(
                syncOptions: configurationSyncOptions,
                load: { try await updater.fetchAdlists() },
                toggle: { list, enabled, scope in
                    try await listUpdater.setAdlist(
                        list,
                        enabled: enabled,
                        from: updater,
                        scope: scope
                    )
                },
                updateGravity: { try await updater.updateGravity() },
                gravityLastUpdated: { try await updater.fetchGravityLastUpdated() }
            )
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.blocklistsCardTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
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
            .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
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
                        .foregroundStyle(.primary)
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
            .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Detail") {
    let updater = PiholeSummaryDataUpdater(pihole: .init(name: "Test", address: "1234"))
    let listUpdater = PiholeListUpdater(dataUpdaters: [updater])

    NavigationStack {
        PiholeDetailView(data: .mockData,
                         updater: updater,
                         listUpdater: listUpdater,
                         settingsStore: SettingsStore())
    }
}
