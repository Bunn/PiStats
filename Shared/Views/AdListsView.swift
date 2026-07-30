//
//  AdListsView.swift
//  PiStats
//
//  Full-screen blocklist manager: lists the Pi-hole's blocklists with per-row
//  enable/disable toggles. Loads on appear via an injected loader and applies
//  toggles optimistically, reverting on failure. Pushed like the query log.
//  Pi-hole v6 only — callers gate on version before passing the closures.
//

import SwiftUI
import PiStatsCore

struct AdListsView: View {
    let syncOptions: PiholeConfigurationSyncOptions
    let load: () async throws -> [AdList]
    let toggle: (AdList, Bool, PiholeConfigurationChangeScope) async throws -> Void
    var updateGravity: (() async throws -> Void)? = nil
    var gravityLastUpdated: (() async throws -> Date?)? = nil

    @State private var lists: [AdList] = []
    @State private var hasLoaded = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pendingChange: PendingAdListChange?

    private struct PendingAdListChange {
        let list: AdList
        let enabled: Bool
    }

    private var blockLists: [AdList] {
        lists.filter { $0.isBlocklist }
    }

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(.secondary)
                    Button("Retry") { Task { await reload() } }
                }
            } else if hasLoaded && blockLists.isEmpty {
                Section {
                    Text("No blocklists configured.").foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(blockLists) { list in
                        Toggle(isOn: binding(for: list)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label(for: list))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                if let comment = list.comment, !comment.isEmpty {
                                    Text(comment)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        #if os(macOS)
                        .toggleStyle(.switch)
                        #endif
                    }
                } header: {
                    if !blockLists.isEmpty {
                        Text("\(blockLists.count) blocklists")
                    }
                }
            }

            if let updateGravity {
                Section {
                    GravityUpdateButton(action: updateGravity, lastUpdatedProvider: gravityLastUpdated)
                }
            }
        }
        .overlay {
            if isLoading && !hasLoaded {
                ProgressView()
            }
        }
        .navigationTitle("Blocklists")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .piholeConfigurationSyncDialog(
            pendingChange: $pendingChange,
            options: syncOptions,
            perform: perform
        )
        .task { await reload() }
        .refreshable { await reload() }
    }

    private func binding(for list: AdList) -> Binding<Bool> {
        Binding(
            get: { lists.first(where: { $0.id == list.id })?.enabled ?? list.enabled },
            set: { newValue in requestSetEnabled(list, newValue) }
        )
    }

    private func requestSetEnabled(_ list: AdList, _ enabled: Bool) {
        let change = PendingAdListChange(list: list, enabled: enabled)
        if syncOptions.requiresScopeConfirmation {
            pendingChange = change
        } else {
            perform(change, scope: syncOptions.automaticScope)
        }
    }

    private func perform(
        _ change: PendingAdListChange,
        scope: PiholeConfigurationChangeScope
    ) {
        Task {
            await setEnabled(change.list, change.enabled, scope: scope)
        }
    }

    private func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            lists = try await load()
            hasLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setEnabled(
        _ list: AdList,
        _ enabled: Bool,
        scope: PiholeConfigurationChangeScope
    ) async {
        applyLocal(list, enabled: enabled) // optimistic
        do {
            try await toggle(list, enabled, scope)
        } catch {
            if (error as? PiholeConfigurationSyncError)?.currentPiholeWasUpdated != true {
                applyLocal(list, enabled: !enabled) // revert
            }
            errorMessage = error.localizedDescription
        }
    }

    private func applyLocal(_ list: AdList, enabled: Bool) {
        guard let index = lists.firstIndex(where: { $0.id == list.id }) else { return }
        let existing = lists[index]
        lists[index] = AdList(id: existing.id,
                              address: existing.address,
                              enabled: enabled,
                              type: existing.type,
                              comment: existing.comment,
                              groups: existing.groups,
                              dateUpdated: existing.dateUpdated)
    }

    private func label(for list: AdList) -> String {
        URL(string: list.address)?.host ?? list.address
    }
}
