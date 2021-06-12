//
//  MacContentView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI
import PiStatsCore


struct ContentView: View {
    @State private var favoriteColor = 0
    private let itemPadding: CGFloat = 15
    @EnvironmentObject var summaryDataProvider: SummaryDataProvider
    @EnvironmentObject var monitorDataProvider: MonitorDataProvider
    
    var body: some View {
        VStack {
            
            HStack {
                Picker(selection: $favoriteColor, label: HStack {
                    Circle().frame(width: 10, height: 10)
                        .foregroundColor(Color("statusOnline"))
                    Text("Enabled")
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
            
            if let summary = summaryDataProvider.summaryDisplay {
                SummaryItemsList(summaryDisplay: summary)
            } else {
                Text("Error")
                //SummaryItemsList(summaryDisplay: summary).redacted(reason: .placeholder
            }
            
            Divider()
            if let display = monitorDataProvider.monitorDisplay {
                MonitorGridView(display: display)
            } else {
                Text("Error")
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

struct MacContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SummaryDataProvider.preview())
            .environmentObject(MonitorDataProvider.preview())
    }
}
