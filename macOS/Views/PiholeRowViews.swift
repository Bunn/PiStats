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
    let onEditTapped: () -> Void

    init(dataUpdater: PiholeSummaryDataUpdater, onEditTapped: @escaping () -> Void) {
        self.dataUpdater = dataUpdater
        self.summary = dataUpdater.summary
        self.onEditTapped = onEditTapped
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.MainView.rowInternalSpacing) {
            headerRow
            statsRow
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
        }
    }

    private var statsRow: some View {
        HStack(spacing: LayoutConstants.MainView.rowItemSpacing) {
            Label(summary.totalQueries,
                  systemImage: SystemImages.globe)
            Label(summary.queriesBlocked,
                  systemImage: SystemImages.handRaised)
            Label(summary.percentageBlocked,
                  systemImage: SystemImages.chartPie)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
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
    VStack(spacing: 8) {
        MacPiholeRowFromDataUpdater(
            dataUpdater: PiholeSummaryDataUpdater(pihole: Pihole(name: "Test Pi-hole", address: "192.168.1.1")),
            onEditTapped: {}
        )
    }
    .padding()
}
