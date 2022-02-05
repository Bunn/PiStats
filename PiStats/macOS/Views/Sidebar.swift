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

            Text("Status Bar")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: Text("a222a")) {
                Label("Status Bar", systemImage: "menubar.rectangle")
            }
            
        }.listStyle(SidebarListStyle())    }
}

struct PiholeSidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
