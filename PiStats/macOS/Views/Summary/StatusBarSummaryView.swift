//
//  MacContentView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI
import PiStatsCore


struct StatusBarSummaryView: View {
    @State private var favoriteColor = 0
    private let itemPadding: CGFloat = 15
    @EnvironmentObject var dataProvider: StatusBarSummaryViewModel
    
    var body: some View {
        VStack {
            
            HStack {
                Picker(selection: $favoriteColor, label: HStack {
                    SummaryStatus(status: dataProvider.status)
                }) {
                    Text("All").tag(0)
                    Text("Pi-hole 1").tag(1)
                    Text("Pi-hole 2").tag(2)
                }
                .frame(width: 200)
                
                Spacer()
                
                
                Button(action: {
                    print("A")
                }) {
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
            
            Divider()
            
            if let display = dataProvider.monitorDisplay {
                MonitorGridView(display: display)
            } else if let error = dataProvider.monitorError {
                Text("Error \(error)")
            } else {
                MonitorGridView(display: MonitorDisplay.preview()).redacted(reason: .placeholder)
            }
            
            
            Divider()
            HStack {
                Button(action: {
                    print("A")
                }) {
                    Text("Quit")
                }
                Spacer()
                Button(action: {
                    openPreferences()
                }) {
                    Text("Preferences")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.leading)
        .padding(.trailing)
    }
    
    private func openPreferences() {
        NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from:nil)
    }
}

struct StatusBarSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarSummaryView()
            .environmentObject(SummaryDataProvider.preview())
            .environmentObject(MonitorDataProvider.preview())
    }
}
