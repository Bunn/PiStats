//
//  CardViewGrid.swift
//  PiStats
//
//  Created by Fernando Bunn on 21/09/2025.
//

import SwiftUI

struct CardViewGrid: View {
    @ObservedObject var data: PiholeSummaryData

    var body: some View {
        VStack {
            HStack {
                PiStatView(type: .totalQueries, data: data.totalQueries)
                PiStatView(type: .queriesBlocked, data: data.queriesBlocked)
            }
            HStack {
                PiStatView(type: .percentageBlocked, data: data.percentageBlocked)
                PiStatView(type: .domainsOnList, data: data.domainsOnList)
            }
        }
    }
}

#if os(iOS)

private struct PiStatView: View {
    let type: StatType
    let data: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(type.title)
                .font(.title3)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            HStack {
                Image(systemName: type.systemImage)
                Text(data)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(type.color), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
    }
}

#else

private struct PiStatView: View {
    let type: StatType
    let data: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(type.title)

                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            HStack {
                Image(systemName: type.systemImage)
                Text(data)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .font(.title2)
            .bold()
            .foregroundStyle(.white)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.color)
        .cornerRadius(LayoutConstants.defaultCornerRadius)
    }
}

#endif

#Preview {
    CardViewGrid(data: .mockData)
}
