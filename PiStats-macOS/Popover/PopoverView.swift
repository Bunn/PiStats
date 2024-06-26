//
//  PopoverView.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/27/24.
//

import SwiftUI

struct PopoverView: View {
    var testData: [PiholeDashboardStatusValue] {
        [.init(status: .totalQueries, value: "123"),
         .init(status: .queriesBlocked, value: "123"),
         .init(status: .percentBlocked, value: "123"),
         .init(status: .domainsOnList, value: "123"),
        ]
    }

    var sensorTest: [PiholeSensosStatusValue] {
        [.init(status: .cpuUsage, value: "0.1, 0.2, 1.3"),
         .init(status: .memoryUsage, value: "12.34%"),
         .init(status: .temperature, value: "23"),
         .init(status: .uptime, value: "21d 34h 34m")]
    }

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack {
            HStack {
                Text("192.168.1.123")
                    .bold()
                Spacer()
            }
            Divider()

          ForEach(testData) { data in
                HStack {
                    Circle()
                        .frame(width: 10, height: 10)
                        .foregroundColor(data.status.color)
                    Text(data.status.title)
                    Spacer()
                    Text(data.value)
                }
            }

            Divider()

            LazyVGrid(columns: columns, spacing: 10) {
                 ForEach(sensorTest) { data in
                     Label {
                         Text(data.value)
                     } icon: {
                         Image(systemName: data.status.systemImageName)
                             .frame(minWidth: 16)
                     }
                     .frame(maxWidth: .infinity, alignment: .leading)
                 }
            }.frame(height: (CGFloat(sensorTest.count) / 2.0) * 30.0)
        }.padding()
    }
}

#Preview {
    PopoverView()
}


struct PiholeSensosStatusValue: Identifiable {
    let id = UUID()
    let status: PiholeSensorStatus
    let value: String

}

enum PiholeSensorStatus {
    case temperature
    case cpuUsage
    case memoryUsage
    case uptime
}

extension PiholeSensorStatus {
    var systemImageName: String {
        switch self {
        case .temperature:
            "thermometer.medium"
        case .cpuUsage:
            "cpu"
        case .memoryUsage:
            "memorychip"
        case .uptime:
            "power"
        }
    }
}

struct PiholeDashboardStatusValue: Identifiable {
    let id = UUID()
    let status: PiholeDashboardStatus
    let value: String
}

enum PiholeDashboardStatus {
    case totalQueries
    case queriesBlocked
    case percentBlocked
    case domainsOnList
}

extension PiholeDashboardStatus {
    var color: Color {
        switch self {
        case .totalQueries:
                .totalQueriesStatus
        case .queriesBlocked:
                .queriesBlockedStatus
        case .percentBlocked:
                .percentBlockedStatus
        case .domainsOnList:
                .domainsBlocklistStatus
        }
    }

    var title: String {
        switch self {

        case .totalQueries:
            "Total Queries"
        case .queriesBlocked:
            "Queries Blocked"
        case .percentBlocked:
            "Percent Blocked"
        case .domainsOnList:
            "Domains on Lists"
        }
    }
}
