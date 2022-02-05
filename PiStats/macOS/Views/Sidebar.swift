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
            Text("Pi-holes")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: PiholeSettingsView(), isActive: $isDefaultItemActive) {
                Label("Inbox", systemImage: "tray.2")
            }

            Text("Preferences")
                .font(.caption)
                .foregroundColor(.secondary)
            NavigationLink(destination: PreferencesView()) {
                Label("Preferences", systemImage: "gearshape")
            }
            
        }.listStyle(SidebarListStyle())}
}

struct PiholeSidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
