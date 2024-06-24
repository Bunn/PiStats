//
//  ContentView.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/15/24.
//

import SwiftUI
import PiStatsCore
import PiholeStorage

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
        print("INIT")

        let server = ServerSettings(version: .v5, host: "a", requestProtocol: .http)
        let credentials = Credentials(secret: "a")
        let pihole = Pihole(serverSettings: server, credentials: credentials)

        self.manager = PiholeManager(pihole: pihole)

        DefaultPiholeStorage().save(data: pihole)

        let pi = DefaultPiholeStorage().retrieveAll(ofType: Pihole.self)
        print(pi)
    }

    deinit {
        print("Deinit")
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
