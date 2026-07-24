//
//  UpstreamsView.swift
//  PiStats
//
//  Breakdown of where queries are answered from — each upstream resolver plus
//  cache and blocklist — as proportional bars.
//

import SwiftUI
import PiStatsCore

struct UpstreamsView: View {
    let result: UpstreamsResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.upstreams.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let maxPercentage = result.upstreams.first?.percentage ?? 1
                ForEach(result.upstreams.prefix(8)) { item in
                    UpstreamRow(item: item, maxPercentage: maxPercentage)
                }
            }
        }
    }
}

private struct UpstreamRow: View {
    let item: UpstreamItem
    let maxPercentage: Double

    private var barFraction: CGFloat {
        guard maxPercentage > 0 else { return 0 }
        return CGFloat(item.percentage / maxPercentage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Text(item.percentage / 100, format: .percent.precision(.fractionLength(0...1)))
                    .font(.caption)
                    .bold()
                    .contentTransition(.numericText())
            }

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppColors.totalQueries.opacity(0.6))
                    .frame(width: geometry.size.width * barFraction, height: 4)
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    UpstreamsView(result: UpstreamsResult(upstreams: [
        UpstreamItem(name: "dns.google", ip: "8.8.8.8", percentage: 62.0),
        UpstreamItem(name: "cache", ip: "", percentage: 24.0),
        UpstreamItem(name: "blocklist", ip: "", percentage: 14.0),
    ]))
    .padding()
}
