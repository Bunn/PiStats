//
//  PiholeSidebar.swift
//  PiStats
//
//  Created by Fernando Bunn on 12/06/2021.
//

import SwiftUI

struct Sidebar: View {
    @State private var isDefaultItemActive = true

    var body: some View {
        List {
            Text("Favorites")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: NavigationList(), isActive: $isDefaultItemActive) {
                Label("Inbox", systemImage: "tray.2")
            }
//            NavigationLink(destination: SentView()) {
//                Label("Sent", systemImage: "paperplane")
//            }
        }.listStyle(SidebarListStyle())    }
}

struct PiholeSidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
