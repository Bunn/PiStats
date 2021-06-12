//
//  SummaryItemsList.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI
import PiStatsCore

struct SummaryItemsList: View {
    var summaryDisplay: SummaryDisplay
    
    var body: some View {
        VStack {
            SummaryItemRowView(itemType: .totalQuery, value: summaryDisplay.totalQueries)
            SummaryItemRowView(itemType: .queryBlocked, value: summaryDisplay.queriesBlocked)
            SummaryItemRowView(itemType: .percentBlocked, value: summaryDisplay.percentBlocked)
            SummaryItemRowView(itemType: .domainsOnBlocklist, value: summaryDisplay.domainsOnBlocklist)
        }
    }
}

struct SummaryItemsList_Previews: PreviewProvider {
    static var previews: some View {
        SummaryItemsList(summaryDisplay: SummaryDisplay.preview())
    }
}
