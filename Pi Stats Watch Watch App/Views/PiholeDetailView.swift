//
//  PiholeDetailView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI
import PiStatsCore

struct PiholeDetailView: View {
    @ObservedObject var updater: PiholeSummaryDataUpdater
    @ObservedObject var settingsStore: SettingsStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with status
                StatusHeaderView(data: updater.summary)
                    .font(.title3)

                // Error message if present
                if updater.summary.hasError {
                    errorView
                }

                // Stats display
                if !updater.summary.hasError {
                    statsView
                }

                // Control buttons
                if !updater.summary.hasError {
                    controlButtons
                }

                // Pi Monitor metrics
                if let metrics = updater.summary.monitorMetrics {
                    metricsSection(metrics: metrics)
                }
            }
            .padding()
        }
        .navigationTitle(updater.summary.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Subviews

    private var errorView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Error")
                    .font(.caption)
                    .fontWeight(.semibold)
            } icon: {
                Image(systemName: SystemImages.errorMessageWarning)
            }
            .foregroundColor(AppColors.statusWarning)

            if let errorMessage = updater.summary.currentError?.humanReadableMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
        )
    }

    @ViewBuilder
    private var statsView: some View {
        if settingsStore.displayStatsAsList {
            ListView(data: updater.summary)
        } else {
            StatsGridView(data: updater.summary)
        }
    }

    private var controlButtons: some View {
        VStack(spacing: 8) {
            if updater.summary.status == .enabled {
                if settingsStore.disablePermanently {
                    // Direct disable button (no timer picker)
                    Button {
                        Task {
                            await updater.disable()
                        }
                    } label: {
                        Label("Disable", systemImage: SystemImages.disablePiholeButton)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.statusOffline)
                } else {
                    // Navigate to disable picker
                    NavigationLink {
                        DisablePickerView(
                            updater: updater,
                            settingsStore: settingsStore
                        )
                    } label: {
                        Label("Disable", systemImage: SystemImages.disablePiholeButton)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.statusOffline)
                }
            } else {
                Button {
                    Task {
                        await updater.enable()
                    }
                } label: {
                    Label("Enable", systemImage: SystemImages.enablePiholeButton)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.statusOnline)
            }
        }
    }

    private func metricsSection(metrics: PiMonitorMetrics) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DEVICE METRICS")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            MetricsView(
                viewModel: MetricItemViewModel(
                    metrics: metrics,
                    temperatureScale: settingsStore.temperatureScale
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    NavigationStack {
        PiholeDetailView(
            updater: PiholeSummaryDataUpdater(
                pihole: Pihole(
                    name: "Pi-hole",
                    address: "192.168.1.100",
                    version: .v5,
                    port: 80,
                    secure: false,
                    token: nil,
                    piMonitor: nil,
                    uuid: UUID()
                )
            ),
            settingsStore: SettingsStore(userDefaults: UserDefaults.shared())
        )
    }
}
