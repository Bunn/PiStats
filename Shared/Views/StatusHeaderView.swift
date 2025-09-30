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
                    .foregroundColor(.primary)
                    .fontWeight(.bold)
            } icon: {
                if data.hasError || data.status == .unknown {
                    Image(systemName: SystemImages.piholeStatusWarning)
                        .foregroundColor(AppColors.statusWarning)
                } else if data.status == .enabled {
                    Image(systemName: SystemImages.piholeStatusOnline)
                        .foregroundColor(AppColors.statusOnline)
                } else {
                    Image(systemName: SystemImages.piholeStatusOffline)
                        .foregroundColor(AppColors.statusOffline)
                }
            }
            .font(.title2)
        }
    }
}


#Preview {
    StatusHeaderView(data: .mockData)
}
