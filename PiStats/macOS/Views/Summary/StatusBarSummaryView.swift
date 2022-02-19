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
    @EnvironmentObject var summaryViewModel: StatusBarSummaryViewModel
    
    var body: some View {
        VStack {
            HStack {
                if summaryViewModel.hasMultiplePiholes {
                    Picker(selection: $summaryViewModel.selectedOption, label: HStack {
                        SummaryStatus(status: summaryViewModel.status)
                    }) {
                        ForEach(summaryViewModel.piholeSelectionOptions, id: \.self) {
                            Text($0.name)
                        }
                    }
                    .frame(width: 200)
                } else {
                    SummaryStatus(status: summaryViewModel.status)
                }
                
                Spacer()
                
                Button {
                    summaryViewModel.toggleStatus()
                } label: {
                    Text(summaryViewModel.buttonFormattedStatus)
                }
            }
            
            Divider()

            if let summary = summaryViewModel.summaryDisplay {
                SummaryItemsList(summaryDisplay: summary)
            } else if let error = summaryViewModel.summaryError {
                Text("Error \(error)")
            } else {
                SummaryItemsList(summaryDisplay: SummaryDisplay.preview()).redacted(reason: .placeholder)
            }
            
            if summaryViewModel.hasMonitorEnabled {
                Divider()
                
                if let display = summaryViewModel.monitorDisplay {
                    MonitorGridView(display: display)
                } else if let error = summaryViewModel.monitorError {
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
        summaryViewModel.openPreferences()
    }
}

struct StatusBarSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBarSummaryView()
            .environmentObject(SummaryDataProvider.preview())
            .environmentObject(MonitorDataProvider.preview())
    }
}
