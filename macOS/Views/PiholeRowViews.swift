//
//  PiholeRowViews.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore

struct MacPiholeRowFromDataUpdater: View {
    @ObservedObject var dataUpdater: PiholeSummaryDataUpdater
    @ObservedObject var summary: PiholeSummaryData
    let temperatureScale: TemperatureScale
    let onEditTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.MainView.rowInternalSpacing) {
            headerRow
            PiholeDetailContentView(
                data: summary,
                temperatureScale: temperatureScale,
                displayStatsAsList: true,
                onClearMessages: { await dataUpdater.clearMessages() }
            )
        }
        .padding(.vertical, LayoutConstants.MainView.rowVerticalPadding)
    }

    private var headerRow: some View {
        HStack {
            PiholeStatusIcon(status: summary.status,
                           hasError: summary.hasError)

            Text(dataUpdater.pihole.name)
                .font(.headline)

            Spacer()

            Button(action: onEditTapped) {
                Image(systemName: SystemImages.gearshape)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help(UserText.MainView.editTooltip)
        }
    }
}

struct PiholeStatusIcon: View {
    let status: PiholeStatus
    let hasError: Bool
    
    var body: some View {
        Group {
            if hasError || status == .unknown {
                Image(systemName: SystemImages.exclamationmarkShieldFill)
                    .foregroundStyle(.yellow)
            } else if status == .enabled {
                Image(systemName: SystemImages.checkmarkShieldFill)
                    .foregroundStyle(.green)
            } else {
                Image(systemName: SystemImages.xmarkShieldFill)
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    let updater = PiholeSummaryDataUpdater(pihole: Pihole(name: "Test Pi-hole", address: "192.168.1.1"))
    return VStack(spacing: 8) {
        MacPiholeRowFromDataUpdater(
            dataUpdater: updater,
            summary: updater.summary,
            temperatureScale: .celsius,
            onEditTapped: {}
        )
    }
    .padding()
}
