//
//  SwiftUIView.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import SwiftUI

struct SummaryItemRowView: View {
    let itemType: SummaryItemType
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 10, height: 10)
                .foregroundColor(itemType.color)
            Text(itemType.name)
            Spacer()
            Text("1234")
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryItemRowView(itemType: .domainsOnBlocklist)
    }
}
