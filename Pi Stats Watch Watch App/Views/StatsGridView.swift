//
//  StatsGridView.swift
//  PiStats Watch
//
//  Created by Claude Code
//

import SwiftUI
import WatchKit

struct StatsGridView: View {
    @ObservedObject var data: PiholeSummaryData

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatCardView(
                    type: .totalQueries,
                    value: data.totalQueries
                )

                StatCardView(
                    type: .queriesBlocked,
                    value: data.queriesBlocked
                )
            }

            HStack(spacing: 0) {
                StatCardView(
                    type: .percentageBlocked,
                    value: data.percentageBlocked
                )

                StatCardView(
                    type: .domainsOnList,
                    value: data.domainsOnList
                )
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Stat Card View

struct StatCardView: View {
    let type: StatType
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: type.systemImage)
                .font(.system(size: 16))
                .foregroundColor(type.color)

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())

            Text(type.shortTitle)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(type.color.opacity(0.15))
        )
    }
}

// MARK: - StatType Extension for Short Titles

extension StatType {
    var shortTitle: String {
        switch self {
        case .totalQueries:
            return "Queries"
        case .queriesBlocked:
            return "Blocked"
        case .percentageBlocked:
            return "Percent"
        case .domainsOnList:
            return "Domains"
        }
    }
}

#Preview {
    StatsGridView(data: .mockData)
}
