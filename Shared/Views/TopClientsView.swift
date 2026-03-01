//
//  TopClientsView.swift
//  PiStats
//
//  Created by Fernando Bunn on 01/03/2026.
//

import SwiftUI
import PiStatsCore

struct TopClientsView: View {
    let topClients: TopClientsResult
    @State private var selectedTab: ClientTab = .blocked

    enum ClientTab: String, CaseIterable {
        case blocked = "Most Blocked"
        case active = "Most Active"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $selectedTab) {
                ForEach(ClientTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            let items = selectedTab == .active ? topClients.topActive : topClients.topBlocked

            if items.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(items.prefix(5).enumerated()), id: \.element.id) { index, item in
                    TopClientRow(item: item, rank: index + 1, maxCount: items.first?.count ?? 1, isBlocked: selectedTab == .blocked)
                }
            }
        }
    }
}

private struct TopClientRow: View {
    let item: TopClientItem
    let rank: Int
    let maxCount: Int
    let isBlocked: Bool

    private var barFraction: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(item.count) / CGFloat(maxCount)
    }

    private var barColor: Color {
        isBlocked ? AppColors.queriesBlocked : AppColors.totalQueries
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.displayName)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    if !item.name.isEmpty {
                        Text(item.ip)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(item.count.formatted())
                    .font(.caption)
                    .bold()
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor.opacity(0.6))
                    .frame(width: geometry.size.width * barFraction, height: 4)
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    TopClientsView(topClients: TopClientsResult(
        topActive: [
            TopClientItem(ip: "192.168.1.100", name: "MacBook-Pro", count: 5000),
            TopClientItem(ip: "192.168.1.101", name: "iPhone", count: 3200),
            TopClientItem(ip: "192.168.1.150", name: "", count: 1500),
        ],
        topBlocked: [
            TopClientItem(ip: "192.168.1.200", name: "IoT-Camera", count: 2400),
            TopClientItem(ip: "192.168.1.201", name: "Smart-TV", count: 1800),
            TopClientItem(ip: "192.168.1.202", name: "Echo-Dot", count: 900),
        ]
    ))
    .padding()
}
