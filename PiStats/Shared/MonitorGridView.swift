//
//  MonitorGridView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI

fileprivate struct MonitorItem: Identifiable {
    let value: String
    let itemType: MonitorItemType
    let helpText: String
    let id: UUID = UUID()
}

struct MonitorGridView: View {
    private let imageSize: CGFloat = 15

    private func getMonitorItems() -> [MonitorItem] {
        return [
            MonitorItem(value: "123", itemType: .temperature, helpText: "Raspberry Pi temperature"),
            MonitorItem(value: "123", itemType: .uptime, helpText: "Raspberry Pi temperature"),
            MonitorItem(value: "123", itemType: .loadAverage, helpText: "Raspberry Pi temperature"),
            MonitorItem(value: "123", itemType: .memoryPercentUsage, helpText: "Raspberry Pi temperature"),
        ]
    }

    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(getMonitorItems()) { item in
                Label(title: {
                    Text(item.value)
                }, icon: {
                    item.itemType.icon
                        .frame(width: imageSize, height: imageSize)
                })
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(.footnote)
                .help(item.helpText)
            }
        }
    }
}


struct MonitorGridView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorGridView()
    }
}
