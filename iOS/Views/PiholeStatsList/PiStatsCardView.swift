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

            if let metrics = data.monitorMetrics {
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
    NavigationStack {
        PiStatsCardView(data: .mockData, updater: .init(pihole: .init(name: "Test", address: "1234", version: .v5)), settingsStore: SettingsStore())
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
                PiholeDetailView(data: data, updater: updater, settingsStore: settingsStore)
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
    @ObservedObject var settingsStore: SettingsStore
    @State private var toast: String?
    @State private var actionError: String?

    private var isV6: Bool { updater.pihole.version == .v6 }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PiholeDetailContentView(
                    data: data,
                    temperatureScale: settingsStore.temperatureScale,
                    showsStats: false,
                    showsMetrics: false,
                    onClearMessages: { await updater.clearMessages() },
                    onLoadDenyRules: isV6 ? { try await updater.fetchDomains(type: .deny, kind: .regex).map(\.domain) } : nil,
                    onBlockRules: isV6 ? { rules in try await updater.addDomains(rules.map { DomainRule(domain: $0, type: .deny, kind: .regex, comment: "Blocked by PiStats") }) } : nil,
                    onUnblockRules: isV6 ? { rules in try await updater.removeDomains(rules.map { DomainRule(domain: $0, type: .deny, kind: .regex) }) } : nil,
                    onQuickAddDomain: isV6 ? { rule in await quickAdd(rule) } : nil
                )
                if isV6 {
                    blocklistsCard
                    domainsCard
                }
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

    private func quickAdd(_ rule: DomainRule) async {
        do {
            try await updater.addDomains([rule])
            toast = rule.type == .allow ? UserText.domainAddedToAllow(rule.domain) : UserText.domainAddedToBlock(rule.domain)
        } catch {
            actionError = error.localizedDescription
        }
    }

    private var domainActions: DomainManagementActions {
        DomainManagementActions(
            loadAll: { try await updater.fetchAllDomains() },
            add: { try await updater.addDomains($0) },
            remove: { try await updater.removeDomains($0) },
            setEnabled: { rule, enabled in try await updater.setDomain(rule, enabled: enabled) }
        )
    }

    private var queryLogCard: some View {
        NavigationLink {
            QueryLogView(updater: updater)
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
            AdListsView(load: { try await updater.fetchAdlists() },
                        toggle: { list, enabled in try await updater.setAdlist(list, enabled: enabled) },
                        updateGravity: { try await updater.updateGravity() },
                        gravityLastUpdated: { try await updater.fetchGravityLastUpdated() })
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
    NavigationStack {
        PiholeDetailView(data: .mockData,
                         updater: .init(pihole: .init(name: "Test", address: "1234", version: .v5)),
                         settingsStore: SettingsStore())
    }
}
