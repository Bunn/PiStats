//
//  ContentView.swift
//  PiStatsMini Watch App
//
//  Created by Fernando Bunn on 24/07/2026.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var dashboard: WatchDashboardModel

    init() {
        _dashboard = State(initialValue: WatchDashboardModel())
    }

    init(dashboard: WatchDashboardModel) {
        _dashboard = State(initialValue: dashboard)
    }

    var body: some View {
        NavigationStack {
            Group {
                if dashboard.piholes.isEmpty {
                    WatchEmptyStateView(
                        message: dashboard.emptyStateMessage,
                        isSyncing: dashboard.isSyncing,
                        syncAction: dashboard.requestConfigurations
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: WatchDesign.cardSpacing) {
                            if dashboard.connectedPiholeCount > 0 {
                                WatchAllBlockingControlView(
                                    dashboard: dashboard
                                )
                            }

                            ForEach(dashboard.piholes) { pihole in
                                WatchPiholeCardView(model: pihole)
                            }
                        }
                        .padding(.horizontal, WatchDesign.screenPadding)
                        .padding(.bottom, WatchDesign.cardSpacing)
                    }
                    .refreshable {
                        await dashboard.refreshAll()
                    }
                }
            }
            .navigationTitle("Pi Stats")
            .navigationDestination(for: UUID.self) { id in
                if let pihole = dashboard.pihole(withID: id) {
                    WatchPiholeDetailView(model: pihole)
                } else {
                    ContentUnavailableView(
                        "Pi-hole unavailable",
                        systemImage: "wifi.exclamationmark"
                    )
                }
            }
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            dashboard.startConnectivity()
            await dashboard.refreshAll()
        }
    }
}

#Preview {
    ContentView()
}
