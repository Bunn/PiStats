//
//  QueryHistoryChartView.swift
//  PiStats
//
//  A data-driven chart of Pi-hole query history over time. Permitted
//  (forwarded + cached) and blocked queries are stacked so the total height of
//  each time bucket represents total queries — the classic Pi-hole look.
//

import SwiftUI
import PiStatsCore
import Charts

struct QueryHistoryChartView: View {
    private let items: [HistoryItem]
    private let permittedColor: Color
    private let blockedColor: Color
    private let showsAxis: Bool
    private let showsLegend: Bool

    /// - Parameters:
    ///   - items: The history buckets to plot (typically ~24h of 10-minute buckets).
    ///   - permittedColor: Colour for the permitted (forwarded + cached) series.
    ///   - blockedColor: Colour for the blocked series.
    ///   - showsAxis: When `false`, hides the X/Y axis marks for a compact, glanceable look.
    ///   - showsLegend: When `false`, hides the series legend.
    init(items: [HistoryItem],
         permittedColor: Color = .green,
         blockedColor: Color = .red,
         showsAxis: Bool = true,
         showsLegend: Bool = true) {
        self.items = items
        self.permittedColor = permittedColor
        self.blockedColor = blockedColor
        self.showsAxis = showsAxis
        self.showsLegend = showsLegend
    }

    private static let permittedLabel = "Permitted"
    private static let blockedLabel = "Blocked"

    var body: some View {
        Chart(items) { item in
            AreaMark(
                x: .value("Time", item.timestamp),
                y: .value("Queries", item.forwarded)
            )
            .foregroundStyle(by: .value("Type", Self.permittedLabel))

            AreaMark(
                x: .value("Time", item.timestamp),
                y: .value("Queries", item.blocked)
            )
            .foregroundStyle(by: .value("Type", Self.blockedLabel))
        }
        .chartForegroundStyleScale([
            Self.permittedLabel: permittedColor,
            Self.blockedLabel: blockedColor
        ])
        .chartLegend(showsLegend ? .visible : .hidden)
        .chartXAxis { xAxisContent }
        .chartYAxis { yAxisContent }
    }

    @AxisContentBuilder
    private var xAxisContent: some AxisContent {
        if showsAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { _ in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .narrow)))
            }
        }
    }

    @AxisContentBuilder
    private var yAxisContent: some AxisContent {
        if showsAxis {
            AxisMarks()
        }
    }
}

#Preview("Detailed") {
    QueryHistoryChartView(items: HistoryItem.previewSamples)
        .frame(height: 180)
        .padding()
}

#Preview("Compact") {
    QueryHistoryChartView(items: HistoryItem.previewSamples,
                          showsAxis: false,
                          showsLegend: false)
        .frame(height: 60)
        .padding()
}

private extension HistoryItem {
    /// Synthetic ~24h history (10-minute buckets) for previews.
    static var previewSamples: [HistoryItem] {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        return (0..<144).map { index in
            let t = now.addingTimeInterval(Double(index - 144) * 600)
            let base = 20 + Int((sin(Double(index) / 12) + 1) * 40)
            let blocked = max(0, base / 4 + (index % 7))
            return HistoryItem(timestamp: t, blocked: blocked, forwarded: base)
        }
    }
}
