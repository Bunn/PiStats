//
//  PiTopDomainsWidget.swift
//  PiStatsWidget
//
//  Created by Fernando Bunn on 28/02/2026.
//

import WidgetKit
import SwiftUI
import PiStatsCore
import AppIntents

// MARK: - Constants

private enum TopDomainsConstants {
    enum Layout {
        static let mainSpacing: CGFloat = 6
        static let domainSpacing: CGFloat = 4
        static let barHeight: CGFloat = 3
        static let barCornerRadius: CGFloat = 1.5
    }
}

// MARK: - Pi Top Domains Widget

struct PiTopDomainsWidget: Widget {
    let kind: String = "PiTopDomainsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PiholeSelectionIntent.self,
            provider: WidgetDataProvider()
        ) { entry in
            PiTopDomainsWidgetView(entry: entry)
        }
        .configurationDisplayName("Top Blocked Domains")
        .description("See your most blocked domains at a glance")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget View

struct PiTopDomainsWidgetView: View {
    let entry: PiStatsEntry
    @Environment(\.widgetFamily) private var family

    private var itemCount: Int {
        family == .systemMedium ? 5 : 3
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TopDomainsConstants.Layout.mainSpacing) {
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
            Image(systemName: "chart.bar")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentView: some View {
        if let topDomains = entry.widgetData?.topDomains,
           !topDomains.topBlocked.isEmpty {
            domainsListView(items: Array(topDomains.topBlocked.prefix(itemCount)))
        } else if entry.widgetData != nil {
            placeholderView
        } else {
            placeholderView
        }
    }

    private func domainsListView(items: [TopDomainItem]) -> some View {
        let maxCount = items.first?.count ?? 1

        return VStack(alignment: .leading, spacing: TopDomainsConstants.Layout.domainSpacing) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                DomainRow(
                    item: item,
                    maxCount: maxCount,
                    showBar: family == .systemMedium
                )
            }
            Spacer(minLength: 0)
        }
    }

    private var placeholderView: some View {
        VStack(spacing: TopDomainsConstants.Layout.domainSpacing) {
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

// MARK: - Domain Row

private struct DomainRow: View {
    let item: TopDomainItem
    let maxCount: Int
    let showBar: Bool

    private var barFraction: CGFloat {
        guard maxCount > 0 else { return 0 }
        return CGFloat(item.count) / CGFloat(maxCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack {
                Text(item.domain)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatCount(item.count))
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.queriesBlocked)
            }

            if showBar {
                GeometryReader { geometry in
                    RoundedRectangle(cornerRadius: TopDomainsConstants.Layout.barCornerRadius)
                        .fill(AppColors.queriesBlocked.opacity(0.5))
                        .frame(
                            width: geometry.size.width * barFraction,
                            height: TopDomainsConstants.Layout.barHeight
                        )
                }
                .frame(height: TopDomainsConstants.Layout.barHeight)
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
    PiTopDomainsWidget()
} timeline: {
    PiStatsEntry.placeholder()
}
