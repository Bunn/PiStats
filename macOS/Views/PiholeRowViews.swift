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
    let onEditTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: LayoutConstants.MainView.rowInternalSpacing) {
            headerRow
            statsRow
        }
        .padding(.vertical, LayoutConstants.MainView.rowVerticalPadding)
    }
    
    private var headerRow: some View {
        HStack {
            PiholeStatusIcon(status: dataUpdater.summary.status, 
                           hasError: dataUpdater.summary.hasError)
            
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
    
    private var statsRow: some View {
        HStack(spacing: LayoutConstants.MainView.rowItemSpacing) {
            Label(dataUpdater.summary.totalQueries, 
                  systemImage: SystemImages.globe)
            Label(dataUpdater.summary.queriesBlocked, 
                  systemImage: SystemImages.handRaised)
            Label(dataUpdater.summary.percentageBlocked, 
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
