//
//  PiholeNavigationList.swift
//  PiStats
//
//  Created by Fernando Bunn on 12/06/2021.
//

import SwiftUI
let allMessages = Array(0...100).map(String.init)


struct NavigationList: View {
    var body: some View {
        List(allMessages, id: \.self) { message in
            NavigationLink(destination: NavigationContentView(message: message)) {
                Text(message)
            }
        }
        .navigationTitle("Inbox")
        .toolbar {
            Button(action: { /* Open filters */ }) {
                Image(systemName: "line.horizontal.3.decrease.circle")
            }
        }
    }
}

struct PiholeNavigationList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationList()
    }
}
