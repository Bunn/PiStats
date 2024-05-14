//
//  ContentView.swift
//  PiStats
//
//  Created by Fernando Bunn on 5/14/24.
//

import SwiftUI
import PiStatsCore

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            print("potato")

            let server = ServerSettings(version: .v5, host: "x", requestProtocol: .http)
            let credentials = Credentials(apiToken: "x")
            let pihole = Pihole(serverSettings: server, credentials: credentials)

            let manager = PiholeManager(pihole: pihole)

            Task {
                try await manager.updateSummary()
                print("P \(manager.pihole.summary)")
            }
        }
    }
}

#Preview {
    ContentView()
}
