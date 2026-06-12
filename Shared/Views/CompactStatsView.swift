//
//  CompactStatsView.swift
//  PiStats
//
//  The two at-a-glance headline numbers shown on the compact card face:
//  total queries and percentage blocked. The remaining stats live in the
//  detail view.
//

import SwiftUI

struct CompactStatsView: View {
    @ObservedObject var data: PiholeSummaryData

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            stat(.totalQueries, value: data.totalQueries)
            stat(.percentageBlocked, value: data.percentageBlocked)
        }
    }

    private func stat(_ type: StatType, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(type.title)
                .font(.caption2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 4) {
                Image(systemName: type.systemImage)
                Text(value)
                    .contentTransition(.numericText())
            }
            .font(.title3)
            .bold()
            .foregroundStyle(type.color)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CompactStatsView(data: .mockData)
        .padding()
}
