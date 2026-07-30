//
//  BlockServicesView.swift
//  PiStats
//
//  One-tap blocking of well-known services via regex deny rules. Loads the
//  current deny rules once, derives each service's blocked state from them, and
//  applies toggles optimistically (reverting on failure). Context-agnostic; all
//  work is injected. Pi-hole v6 only — callers gate on version.
//

import SwiftUI
import PiStatsCore

struct BlockServicesView: View {
    let syncOptions: PiholeConfigurationSyncOptions
    let loadRules: () async throws -> [String]
    let block: ([String], PiholeConfigurationChangeScope) async throws -> Void
    let unblock: ([String], PiholeConfigurationChangeScope) async throws -> Void

    @State private var denyRules: Set<String> = []
    @State private var hasLoaded = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var pendingChange: PendingServiceChange?

    private struct PendingServiceChange {
        let service: BlockableService
        let blocked: Bool
    }

    var body: some View {
        Group {
            if isLoading && !hasLoaded {
                HStack {
                    ProgressView()
                        #if os(macOS)
                        .controlSize(.small)
                        #endif
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Retry") { Task { await reload() } }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(BlockableService.catalog) { service in
                        Toggle(isOn: binding(for: service)) {
                            Label(service.name, systemImage: service.systemImage)
                                .font(.subheadline)
                        }
                        #if os(macOS)
                        .toggleStyle(.switch)
                        #endif
                    }
                }
            }
        }
        .piholeConfigurationSyncDialog(
            pendingChange: $pendingChange,
            options: syncOptions,
            perform: perform
        )
        .task { await reload() }
    }

    private func binding(for service: BlockableService) -> Binding<Bool> {
        Binding(
            get: { service.isBlocked(in: denyRules) },
            set: { newValue in requestSetBlocked(service, newValue) }
        )
    }

    private func requestSetBlocked(_ service: BlockableService, _ blocked: Bool) {
        let change = PendingServiceChange(service: service, blocked: blocked)
        if syncOptions.requiresScopeConfirmation {
            pendingChange = change
        } else {
            perform(change, scope: syncOptions.automaticScope)
        }
    }

    private func perform(
        _ change: PendingServiceChange,
        scope: PiholeConfigurationChangeScope
    ) {
        Task {
            await setBlocked(change.service, change.blocked, scope: scope)
        }
    }

    private func reload() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            denyRules = Set(try await loadRules())
            hasLoaded = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setBlocked(
        _ service: BlockableService,
        _ blocked: Bool,
        scope: PiholeConfigurationChangeScope
    ) async {
        let previous = denyRules
        if blocked {
            denyRules.formUnion(service.rules)
        } else {
            denyRules.subtract(service.rules)
        }
        do {
            if blocked {
                try await block(service.rules, scope)
            } else {
                try await unblock(service.rules, scope)
            }
        } catch {
            if (error as? PiholeConfigurationSyncError)?.currentPiholeWasUpdated != true {
                denyRules = previous // revert
            }
            errorMessage = error.localizedDescription
        }
    }
}
