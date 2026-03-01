//
//  PiTopClientsWidget.swift
//  PiStatsWidget
//
//  Created by Fernando Bunn on 01/03/2026.
//

import WidgetKit
import SwiftUI
import PiStatsCore
import AppIntents

// MARK: - Constants

private enum TopClientsConstants {
    enum Layout {
        static let mainSpacing: CGFloat = 6
        static let clientSpacing: CGFloat = 4
        static let barHeight: CGFloat = 3
        static let barCornerRadius: CGFloat = 1.5
    }
}

// MARK: - Pi Top Clients Widget

struct PiTopClientsWidget: Widget {
    let kind: String = "PiTopClientsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PiholeSelectionIntent.self,
            provider: WidgetDataProvider()
        ) { entry in
            PiTopClientsWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Clients")
        .description("See which devices make the most queries and get the most blocks")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct PiTopClientsWidgetView: View {
    let entry: PiStatsEntry
    @Environment(\.widgetFamily) private var family

    private var itemCount: Int {
        family == .systemMedium ? 4 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TopClientsConstants.Layout.mainSpacing) {
            headerView
            Divider()
            contentView
        }
        .padding()
        .widgetBackground {
            Color(.systemGroupedBackground)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Text(entry.widgetData?.pihole.name ?? "Select Pi-hole")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: "person.2")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if let topClients = entry.widgetData?.topClients,
           !topClients.topActive.isEmpty {
            clientsListView(items: Array(topClients.topActive.prefix(itemCount)))
        } else {
            placeholderView
        }
    }

    private func clientsListView(items: [TopClientItem]) -> some View {
        let maxCount = items.first?.count ?? 1

        return VStack(alignment: .leading, spacing: TopClientsConstants.Layout.clientSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                ClientRow(
                    item: item,
                    maxCount: maxCount,
                    showBar: family == .systemMedium
                )
            }
            Spacer(minLength: 0)
        }
    }

    private var placeholderView: some View {
        VStack(spacing: TopClientsConstants.Layout.clientSpacing) {
            ForEach(0..<itemCount, id: \.self) { _ in
                HStack {
                    Text("---")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("—")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Client Row

private struct ClientRow: View {
    let item: TopClientItem
    let maxCount: Int
    let showBar: Bool

    private var barFraction: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(item.count) / CGFloat(maxCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(item.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatCount(item.count))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.totalQueries)
            }

            if showBar {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: TopClientsConstants.Layout.barCornerRadius)
                        .fill(AppColors.totalQueries.opacity(0.5))
                        .frame(
                            width: geometry.size.width * barFraction,
                            height: TopClientsConstants.Layout.barHeight
                        )
                }
                .frame(height: TopClientsConstants.Layout.barHeight)
            }
        }
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return Double(count).formatted(.number.notation(.compactName))
        }
        return "\(count)"
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    PiTopClientsWidget()
} timeline: {
    PiStatsEntry.placeholder()
}
