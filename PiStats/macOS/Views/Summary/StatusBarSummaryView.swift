//
//  MacContentView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI
import PiStatsCore

struct StatusBarSummaryView: View {
    private let itemPadding: CGFloat = 15
    @EnvironmentObject var dataProvider: StatusBarSummaryViewModel
    
    var body: some View {
        VStack {
            HStack {
                if dataProvider.hasMultiplePiholes {
                    Picker(selection: $dataProvider.selectedOption, label: HStack {
                        SummaryStatus(status: dataProvider.status)
                    }) {
                        ForEach(dataProvider.piholeSelectionOptions, id: \.self) {
                            Text($0.name)
                        }
                    }
                    .frame(width: 200)
                } else {
                    SummaryStatus(status: dataProvider.status)
                }
                
                Spacer()
                
                Button {
                    print("test")
                } label: {
                    Text("Enable")
                }
            }
            
            Divider()
            
            if let summary = dataProvider.summaryDisplay {
                SummaryItemsList(summaryDisplay: summary)
            } else if let error = dataProvider.summaryError {
                Text("Error \(error)")
            } else {
                SummaryItemsList(summaryDisplay: SummaryDisplay.preview()).redacted(reason: .placeholder)
            }
            
            if dataProvider.hasMonitorEnabed {
                Divider()
                
                if let display = dataProvider.monitorDisplay {
                    MonitorGridView(display: display)
                } else if let error = dataProvider.monitorError {
                    Text("Error \(error)")
                } else {
                    MonitorGridView(display: MonitorDisplay.preview()).redacted(reason: .placeholder)
                }
            }
            
            Divider()
            HStack {
                Button {
                    print("test")
                } label: {
                    Text("Quit")
                }
                Spacer()
                Button {
                    openPreferences()
                } label: {
                    Text("Preferences")
                }

            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.leading)
        .padding(.trailing)
    }
    
    private func openPreferences() {
        NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from: nil)
    }
}

struct StatusBarSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarSummaryView()
            .environmentObject(SummaryDataProvider.preview())
            .environmentObject(MonitorDataProvider.preview())
    }
}
