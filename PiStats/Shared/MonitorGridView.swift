//
//  MonitorGridView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI
import PiStatsCore

fileprivate struct MonitorItem: Identifiable {
    let value: String
    let itemType: MonitorItemType
    let helpText: String
    let id: UUID = UUID()
}

struct MonitorGridView: View {
    private let imageSize: CGFloat = 15
    let display: MonitorDisplay

    private func getMonitorItems() -> [MonitorItem] {
        return [
            MonitorItem(value: display.temperature, itemType: .temperature, helpText: "Raspberry Pi temperature"),
            MonitorItem(value: display.uptime, itemType: .uptime, helpText: "Raspberry Pi uptime"),
            MonitorItem(value: display.loadAverage, itemType: .loadAverage, helpText: "Raspberry Pi load average"),
            MonitorItem(value: display.memoryPercentUsage, itemType: .memoryPercentUsage, helpText: "Raspberry Pi memory usage"),
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
                .font(.callout)
                .help(item.helpText)
            }
        }
    }
}


struct MonitorGridView_Previews: PreviewProvider {
    static var previews: some View {
        MonitorGridView(display: MonitorDisplay.preview())
    }
}
