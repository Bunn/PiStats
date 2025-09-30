//
//  ListView.swift
//  PiStats
//
//  Created by Fernando Bunn on 21/09/2025.
//


import SwiftUI

struct ListView: View {
    @ObservedObject var data: PiholeSummaryData
    
    var body: some View {
        VStack (spacing: spacing) {
            ListViewItem(type: .totalQueries, data: data.totalQueries)
            ListViewItem(type: .queriesBlocked, data: data.queriesBlocked)
            ListViewItem(type: .percentageBlocked, data: data.percentageBlocked)
            ListViewItem(type: .domainsOnList, data: data.domainsOnList)
        }
    }

    private var spacing: CGFloat {
#if os(iOS)
        return 4
#else
        return 8
#endif
    }
}

#if os(iOS)
private struct ListViewItem: View {
    let type: StatType
    let data: String

    var body: some View {
        HStack {
            Group {
                Image(systemName: type.systemImage)
                Text(type.title)
            }
            .bold()
            .foregroundStyle(type.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            Spacer()
            HStack {
                Text(data)
                    .contentTransition(.numericText())
            }
            .bold()
            .foregroundStyle(type.color)
        }
        .cornerRadius(LayoutConstants.defaultCornerRadius)
    }
}
#else
private struct ListViewItem: View {
    let type: StatType
    let data: String

    var body: some View {

        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundColor(type.color)
            Text(type.title)
            Spacer()
            Text(data)
                .bold()
                .foregroundColor(type.color)

        }
        .cornerRadius(LayoutConstants.defaultCornerRadius)
    }
}
#endif

#Preview {
    ListView(data: .mockData)
}
