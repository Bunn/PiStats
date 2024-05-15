//
//  TestView.swift
//  PiStats
//
//  Created by Fernando Bunn on 5/15/24.
//

import SwiftUI
import PiStatsCore

struct TestView: View {
    @State var pihole: Pihole

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text(pihole.status.rawValue)
            Text("lalala \(pihole.summary?.totalQueries ?? 1)")
        }
        .padding()

    }
}

#Preview {
    let server = ServerSettings(version: .v5, host: "1", requestProtocol: .http)
    let credentials = Credentials(apiToken: "1")
    let pihole = Pihole(serverSettings: server, credentials: credentials)

    return TestView(pihole: pihole)
}
