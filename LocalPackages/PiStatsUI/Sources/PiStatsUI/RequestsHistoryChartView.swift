//
//  RequestChartView.swift
//  PiStatsUI
//
//  Created by Fernando Bunn on 29/01/2025.
//

import SwiftUI
import PiStatsCore
import Charts

public struct RequestsHistoryChartView: View {
    @StateObject private var viewModel = RequestsHistoryChartViewModel()

    public init() { }
    
    public var body: some View {
        VStack {
            if viewModel.historyItems.isEmpty {
                Text("Loading...")
            } else {
                Chart {
                    ForEach(viewModel.historyItems) { item in
                        LineMark(
                            x: .value("Date", item.timestamp),
                            y: .value("Blocked", item.blocked),
                            series: .value("type", "Blocked")
                        )
                        .foregroundStyle(.red)

                        LineMark(
                            x: .value("Date", item.timestamp),
                            y: .value("Forwarded", item.forwarded),
                            series: .value("type", "Forwarded")
                        )
                        .foregroundStyle(.green)

                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                        AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .omitted)))
                    }
                }
                .chartYAxis {
                    AxisMarks()
                }
                .padding()
            }

            Button {
                Task {
                    await viewModel.enable()
                }
            } label: {
                Text("ENABLED")
            }

            Button {
                Task {
                    await viewModel.disable()
                }
            } label: {
                Text("DISBALED")
            }

        }
        .task {
            await viewModel.fetchHistory()
            await viewModel.fetchStats()
        }
    }
}

@MainActor
public class RequestsHistoryChartViewModel: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    let client: PiholeAPIClient

    init() {
        let pihole = Pihole(name: "My Pi-hole",
                            address: "192.168.1.123",
                            version: .v5,
                            token: "test")

        self.client = PiholeAPIClient(pihole)
    }


    @MainActor
    func fetchHistory() async {
        do {
            let fetchedHistory = try await client.fetchHistory().sorted { $0.timestamp > $1.timestamp }
                self.historyItems = fetchedHistory

        } catch {
            Log.ui.error("Failed to fetch history: \(String(describing: error), privacy: .public)")
        }
    }

    func enable() async {

        do {
            let status = try await client.enable()
            Log.ui.info("Enable status: \(String(describing: status), privacy: .public)")
        } catch {
            Log.ui.error("Failed to enable: \(String(describing: error), privacy: .public)")

        }
    }

    func disable() async {

        do {
            let status = try await client.disable()
            Log.ui.info("Disable status: \(String(describing: status), privacy: .public)")
        } catch {
            Log.ui.error("Failed to disable: \(String(describing: error), privacy: .public)")

        }
    }

    func fetchStats() async {

        do {
            let summary = try await client.fetchSummary()
            let status = try await client.fetchStatus()

            Log.ui.info("Summary and status fetched")
            Log.ui.debug("Summary: \(String(describing: summary), privacy: .public) Status: \(String(describing: status), privacy: .public)")
        } catch {
            Log.ui.error("Failed to fetch stats: \(String(describing: error), privacy: .public)")

        }
    }
}

