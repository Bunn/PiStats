//
//  SummaryStatus.swift
//  PiStats
//
//  Created by Fernando Bunn on 13/06/2021.
//

import SwiftUI
import PiStatsCore

struct SummaryStatus: View {
    let status: SummaryDisplay.PiholeStatus
    
    var body: some View {
        HStack {
            Circle().frame(width: 10, height: 10)
                .foregroundColor(color())
            Text(statusTitle())
        }
    }
    
    func color() -> Color {
        switch status {
        case .allDisabled:
            return Color("statusOffline")
        case .allEnabled:
            return Color("statusOnline")
        case .enabledAndDisabled:
            return Color("statusWarning")
        }
    }
    
    func statusTitle() -> String {
        switch status {
        case .allDisabled:
            return "Disabled"
        case .allEnabled:
            return "Enabled"
        case .enabledAndDisabled:
            return "Enabled and Disabled"
        }
    }
}

struct SummaryStatus_Previews: PreviewProvider {
    static var previews: some View {
        SummaryStatus(status: .allDisabled)
    }
}
