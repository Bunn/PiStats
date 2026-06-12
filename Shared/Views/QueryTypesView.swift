//
//  QueryTypesView.swift
//  PiStats
//
//  Breakdown of DNS query types (A, AAAA, HTTPS, …) as proportional bars.
//

import SwiftUI
import PiStatsCore

struct QueryTypesView: View {
    let result: QueryTypesResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if result.types.isEmpty {
                Text("No data available")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                let maxPercentage = result.types.first?.percentage ?? 1
                ForEach(result.types.prefix(8), id: \.name) { item in
                    QueryTypeRow(item: item, maxPercentage: maxPercentage)
                }
            }
        }
    }
}

private struct QueryTypeRow: View {
    let item: QueryTypeItem
    let maxPercentage: Double

    private var barFraction: CGFloat {
        guard maxPercentage > 0 else { return 0 }
        return CGFloat(item.percentage / maxPercentage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(item.name)
                    .font(.caption)
                    .lineLimit(1)
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
    QueryTypesView(result: QueryTypesResult(types: [
        QueryTypeItem(name: "A (IPv4)", percentage: 58.2),
        QueryTypeItem(name: "AAAA (IPv6)", percentage: 27.4),
        QueryTypeItem(name: "HTTPS", percentage: 9.1),
        QueryTypeItem(name: "PTR", percentage: 5.3),
    ]))
    .padding()
}
