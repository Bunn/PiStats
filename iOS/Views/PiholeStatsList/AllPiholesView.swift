//
//  AllPiholesView.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/06/2025.
//

import PiStatsCore
import SwiftUI
import Foundation

struct AllPiholesView: View {
    @ObservedObject var listUpdater: PiholeListUpdater
    @ObservedObject var settingsStore: SettingsStore
    
    var body: some View {
        AllPiholesContentView(
            summaries: listUpdater.dataUpdaters.map { $0.summary },
            settingsStore: settingsStore,
            onDisableAll: { timer in
                Task {
                    await disableAllPiholes(timer: timer)
                }
            },
            onEnableAll: {
                Task {
                    await enableAllPiholes()
                }
            }
        )
    }
    
    private func disableAllPiholes(timer: Int?) async {
        await withTaskGroup(of: Void.self) { group in
            for updater in listUpdater.dataUpdaters {
                if updater.summary.status == .enabled {
                    group.addTask {
                        await updater.disable(timer: timer)
                    }
                }
            }
        }
    }
    
    private func enableAllPiholes() async {
        await withTaskGroup(of: Void.self) { group in
            for updater in listUpdater.dataUpdaters {
                if updater.summary.status == .disabled {
                    group.addTask {
                        await updater.enable()
                    }
                }
            }
        }
    }
}

private struct AllPiholesContentView: View {
    let summaries: [PiholeSummaryData]
    @ObservedObject var settingsStore: SettingsStore
    let onDisableAll: (Int?) -> Void
    let onEnableAll: () -> Void
    @State private var showingDisableAllActionSheet = false
    
    private var aggregatedStats: (totalQueries: Int, queriesBlocked: Int, percentage: Double) {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let totalQueries = summaries.compactMap { summary in
            numberFormatter.number(from: summary.totalQueries)?.intValue
        }.reduce(0, +)

        let queriesBlocked = summaries.compactMap { summary in
            numberFormatter.number(from: summary.queriesBlocked)?.intValue
        }.reduce(0, +)

        let percentage = totalQueries > 0 ? (Double(queriesBlocked) / Double(totalQueries)) * 100 : 0.0

        return (totalQueries, queriesBlocked, percentage)
    }

    
    private var hasEnabledPiholes: Bool {
        summaries.contains { $0.status == .enabled }
    }
    
    private var hasDisabledPiholes: Bool {
        summaries.contains { $0.status == .disabled }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("All Pi-holes Combined")
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
                .font(.title2)
                Spacer()
            }


            VStack(spacing: 8) {
                ForEach(summaries) { summary in
                    PiholeStatusRow(summary: summary)
                }
            }

            let stats = aggregatedStats
            
            VStack(spacing: 8) {
                AllPiholesListItem(
                    type: .totalQueries,
                    data: stats.totalQueries.formatted()
                )
                AllPiholesListItem(
                    type: .queriesBlocked,
                    data: stats.queriesBlocked.formatted()
                )
                AllPiholesListItem(
                    type: .percentageBlocked,
                    data: stats.percentage.formattedPercentage()
                )
            }


            if hasDisabledPiholes {
                Button {
                    onEnableAll()
                } label: {
                    HStack {
                        Label("Enable All Pi-holes", systemImage: SystemImages.enablePiholeButton)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .glassEffect(.regular.tint(AppColors.totalQueries).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
                }
            } else if hasEnabledPiholes {
                Button {
                    if settingsStore.disablePermanently {
                        onDisableAll(nil)
                    } else {
                        showingDisableAllActionSheet = true
                    }
                } label: {
                    HStack {
                        Label("Disable All Pi-holes", systemImage: SystemImages.disablePiholeButton)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .glassEffect(.regular.tint(AppColors.statusOffline).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
                }
            }
        }

        .padding()
        .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))

        .actionSheet(isPresented: $showingDisableAllActionSheet) {
            ActionSheet(
                title: Text("Disable All Pi-holes"),
                buttons: createDisableAllActionButtons()
            )
        }
    }
    
    private func createDisableAllActionButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Add custom disable time buttons
        for disableTime in settingsStore.customDisableTimes {
            buttons.append(.default(Text(disableTime.displayName)) {
                onDisableAll(disableTime.seconds)
            })
        }
        
        // Add permanent disable option
        buttons.append(.destructive(Text(UserText.disablePiholeOptionsPermanently)) {
            onDisableAll(nil)
        })
        
        // Add cancel button
        buttons.append(.cancel())
        
        return buttons
    }
}

private struct PiholeStatusRow: View {
    @ObservedObject var summary: PiholeSummaryData
    
    var body: some View {
        HStack {
            // Status Icon
            if summary.hasError || summary.status == .unknown {
                Image(systemName: SystemImages.piholeStatusWarning)
                    .foregroundColor(AppColors.statusWarning)
            } else if summary.status == .enabled {
                Image(systemName: SystemImages.piholeStatusOnline)
                    .foregroundColor(AppColors.statusOnline)
            } else {
                Image(systemName: SystemImages.piholeStatusOffline)
                    .foregroundColor(AppColors.statusOffline)
            }
            
            // Pi-hole Name
            Text(summary.name)
                .font(.body)
                .foregroundColor(.primary)
                .bold()

            Spacer()
            
            // Status Text
            Text(statusText(for: summary.status))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private func statusText(for status: PiholeStatus) -> String {
        switch status {
        case .enabled:
            return "Active"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

private struct AllPiholesStatView: View {
    let type: StatType
    let data: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(type.title)
                .font(.title3)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            HStack {
                Image(systemName: type.systemImage)
                Text(data)
                    .contentTransition(.numericText())
            }
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color)
        .cornerRadius(LayoutConstants.defaultCornerRadius)
    }
}

private struct AllPiholesListItem: View {
    let type: StatType
    let data: String

    var body: some View {
        HStack {
            Group {
                Image(systemName: type.systemImage)
                Text(type.title)
            }
            .bold()
            .foregroundStyle(type.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer()
            HStack {
                Text(data)
                    .contentTransition(.numericText())
            }
            .bold()
            .foregroundStyle(type.color)
        }
        .cornerRadius(LayoutConstants.defaultCornerRadius)
    }
}
