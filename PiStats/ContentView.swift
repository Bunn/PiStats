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

            let server = ServerSettings(version: .v5, host: "192.168.1.168", requestProtocol: .http)
            let credentials = Credentials(apiToken: "992590e383538763d03f45aa1d084efa015a05c93a14d434b8969e3b5e983288")
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
