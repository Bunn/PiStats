//
//  PiholeListView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI
import PiStatsCore

struct PiholeListView: View {
    @StateObject private var listUpdater: PiholeListUpdater
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var settingsStore: SettingsStore

    init(settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        let piholes = piholeStorage.restoreAllPiholes()
        _listUpdater = StateObject(wrappedValue: PiholeListUpdater(piholes))
    }

    var body: some View {
        NavigationStack {
            Group {
                if listUpdater.dataUpdaters.isEmpty {
                    EmptyStateView()
                } else if listUpdater.dataUpdaters.count == 1 {
                    // Single Pi-hole: show detail view directly
                    if let updater = listUpdater.dataUpdaters.first {
                        PiholeDetailView(
                            updater: updater,
                            settingsStore: settingsStore
                        )
                    }
                } else {
                    // Multiple Pi-holes: show list
                    piholeList
                }
            }
            .navigationTitle("Pi-holes")
        }
        .onAppear {
            reloadPiholes()
            listUpdater.startUpdating()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Battery optimization: stop polling when backgrounded
            if newPhase == .active {
                reloadPiholes()
                listUpdater.startUpdating()
            } else {
                listUpdater.stopUpdating()
            }
        }
    }

    private func reloadPiholes() {
        let currentPiholes = piholeStorage.restoreAllPiholes()

        // Remove Pi-holes that no longer exist
        for updater in listUpdater.dataUpdaters {
            if !currentPiholes.contains(where: { $0.uuid == updater.pihole.uuid }) {
                listUpdater.removePihole(updater.pihole)
            }
        }

        // Add new Pi-holes
        for pihole in currentPiholes {
            if !listUpdater.dataUpdaters.contains(where: { $0.pihole.uuid == pihole.uuid }) {
                listUpdater.addPihole(pihole)
            }
        }

        // Update existing Pi-holes in case settings changed
        for pihole in currentPiholes {
            if let existing = listUpdater.dataUpdaters.first(where: { $0.pihole.uuid == pihole.uuid }),
               existing.pihole.address != pihole.address ||
               existing.pihole.token != pihole.token ||
               existing.pihole.port != pihole.port {
                listUpdater.updatePihole(pihole)
            }
        }
    }

    private var piholeList: some View {
        List {
            ForEach(listUpdater.dataUpdaters, id: \.pihole.uuid) { updater in
                NavigationLink {
                    PiholeDetailView(
                        updater: updater,
                        settingsStore: settingsStore
                    )
                } label: {
                    PiholeRowView(updater: updater)
                }
            }
        }
    }
}

// MARK: - Pi-hole Row View

struct PiholeRowView: View {
    @ObservedObject var updater: PiholeSummaryDataUpdater

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                statusIndicator

                Text(updater.summary.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()
            }

            HStack {
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !updater.summary.hasError && updater.summary.status == .enabled {
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(updater.summary.queriesBlocked) blocked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        if updater.summary.hasError || updater.summary.status == .unknown {
            return AppColors.statusWarning
        } else if updater.summary.status == .enabled {
            return AppColors.statusOnline
        } else {
            return AppColors.statusOffline
        }
    }

    private var statusText: String {
        if updater.summary.hasError {
            return UserText.statusNeedsAttention
        }

        switch updater.summary.status {
        case .enabled:
            return UserText.statusEnabled
        case .disabled:
            return UserText.statusDisabled
        case .unknown:
            return UserText.statusUnknown
        }
    }
}

#Preview {
    PiholeListView(settingsStore: SettingsStore(userDefaults: UserDefaults.shared()))
}
