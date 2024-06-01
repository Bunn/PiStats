//
//  ContentView.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/15/24.
//

import SwiftUI
import PiStatsCore

struct ContentView: View {
     @StateObject var manager = Manager()

    var body: some View {
        VStack {
            TestView(pihole: manager.manager.pihole)
        }.onAppear {
            manager.startUpdate()
        }
    }
}

#Preview {
    ContentView()
}


@MainActor
final class Manager: ObservableObject {
    let manager: PiholeManager

    init() {
        let server = ServerSettings(version: .v5, host: "28", requestProtocol: .http)
        let credentials = Credentials(apiToken: "1")
        let pihole = Pihole(serverSettings: server, credentials: credentials)

        self.manager = PiholeManager(pihole: pihole)
    }

    func startUpdate() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            Task { @MainActor in
                self.updatePihole()
            }
        }
    }


    func updatePihole() {
        Task {
            async let summaryUpdate: () = manager.updateSummary()
            async let statusUpdate: () = manager.updateStatus()
            _ = try await (summaryUpdate, statusUpdate)
        }

    }
}

