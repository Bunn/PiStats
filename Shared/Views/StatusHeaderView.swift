//
//  StatusHeaderView.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2025.
//

import SwiftUI
import PiStatsCore

struct StatusHeaderView: View {
    @ObservedObject var data: PiholeSummaryData

    var body: some View {
        HStack {
            Label {
                Text(data.name)
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
            } icon: {
                if data.isRefreshing && !data.hasLoadedStatus {
                    ProgressView()
                        .controlSize(.small)
                        .accessibilityLabel(UserText.statusConnecting)
                } else if data.hasError || data.status == .unknown {
                    Image(systemName: SystemImages.piholeStatusWarning)
                        .foregroundStyle(AppColors.statusWarning)
                } else if data.status == .enabled {
                    Image(systemName: SystemImages.piholeStatusOnline)
                        .foregroundStyle(AppColors.statusOnline)
                } else {
                    Image(systemName: SystemImages.piholeStatusOffline)
                        .foregroundStyle(AppColors.statusOffline)
                }
            }
            .font(.title2)

            if data.isRefreshing && data.hasLoadedStatus {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel(UserText.statusUpdating)
            }
        }
    }
}


#Preview {
    StatusHeaderView(data: .mockData)
}
