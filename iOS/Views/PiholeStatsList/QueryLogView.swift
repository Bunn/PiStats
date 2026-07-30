//
//  QueryLogView.swift
//  PiStats
//
//  A searchable list of recent DNS queries, loaded on demand from the
//  Pi-hole (not part of the periodic summary refresh).
//

import SwiftUI
import PiStatsCore

struct QueryLogView: View {
    let updater: PiholeSummaryDataUpdater
    @ObservedObject var listUpdater: PiholeListUpdater
    let syncOptions: PiholeConfigurationSyncOptions

    @State private var entries: [QueryLogEntry] = []
    @State private var isLoading = true
    @State private var didFail = false
    @State private var searchText = ""
    @State private var toast: String?
    @State private var actionError: String?
    @State private var pendingChange: PendingQueryChange?

    private struct PendingQueryChange {
        let domain: String
        let type: DomainListType
    }

    private var filteredEntries: [QueryLogEntry] {
        guard !searchText.isEmpty else { return entries }
        return entries.filter {
            $0.domain.localizedStandardContains(searchText)
                || $0.client.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        List {
            if isLoading && entries.isEmpty {
                loadingRow
            } else if didFail && entries.isEmpty {
                ContentUnavailableView(
                    "Couldn't Load Queries",
                    systemImage: SystemImages.errorMessageWarning,
                    description: Text("Pull down to try again.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredEntries) { entry in
                    QueryLogRow(
                        entry: entry,
                        onAdd: { type in request(domain: entry.domain, type: type) }
                    )
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(UserText.queryLogTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text(UserText.queryLogSearchPrompt))
        .refreshable { await load() }
        .task { await load() }
        .piholeConfigurationSyncDialog(
            pendingChange: $pendingChange,
            options: syncOptions,
            perform: perform
        )
        .domainActionToast($toast)
        .alert("Couldn't update list", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK", role: .cancel) { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
    }

    private func request(domain: String, type: DomainListType) {
        let change = PendingQueryChange(domain: domain, type: type)
        if syncOptions.requiresScopeConfirmation {
            pendingChange = change
        } else {
            perform(change, scope: syncOptions.automaticScope)
        }
    }

    private func perform(
        _ change: PendingQueryChange,
        scope: PiholeConfigurationChangeScope
    ) {
        Task {
            do {
                try await listUpdater.addDomains(
                    [
                        DomainRule(
                            domain: change.domain,
                            type: change.type,
                            kind: .exact
                        )
                    ],
                    from: updater,
                    scope: scope
                )
                toast = change.type == .allow
                    ? UserText.domainAddedToAllow(change.domain)
                    : UserText.domainAddedToBlock(change.domain)
            } catch {
                if (error as? PiholeConfigurationSyncError)?.currentPiholeWasUpdated == true {
                    toast = change.type == .allow
                        ? UserText.domainAddedToAllow(change.domain)
                        : UserText.domainAddedToBlock(change.domain)
                }
                actionError = error.localizedDescription
            }
        }
    }

    private var loadingRow: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .listRowSeparator(.hidden)
    }

    private func load() async {
        didFail = false
        if entries.isEmpty { isLoading = true }
        do {
            entries = try await updater.fetchQueries(count: 200)
        } catch {
            didFail = true
        }
        isLoading = false
    }
}

private struct QueryLogRow: View {
    let entry: QueryLogEntry
    /// Adds this row's domain to the given list.
    let onAdd: (DomainListType) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.domain)
                    .font(.subheadline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                HStack(spacing: 6) {
                    Text(entry.client)
                    Text("·")
                    Text(entry.type)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text(entry.timestamp, format: .dateTime.hour().minute().second())
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if entry.status == .blocked {
                Button { onAdd(.allow) } label: {
                    Label(UserText.allowDomainAction, systemImage: SystemImages.allowDomain)
                }
                .tint(AppColors.statusOnline)
            } else {
                Button { onAdd(.deny) } label: {
                    Label(UserText.blockDomainAction, systemImage: SystemImages.blockDomain)
                }
                .tint(AppColors.queriesBlocked)
            }
        }
        .contextMenu {
            Button { onAdd(.allow) } label: {
                Label(UserText.allowDomainAction, systemImage: SystemImages.allowDomain)
            }
            Button { onAdd(.deny) } label: {
                Label(UserText.blockDomainAction, systemImage: SystemImages.blockDomain)
            }
        }
    }

    private var statusColor: Color {
        switch entry.status {
        case .blocked: return AppColors.queriesBlocked
        case .forwarded: return AppColors.statusOnline
        case .cached: return AppColors.totalQueries
        case .unknown: return .secondary
        }
    }
}
