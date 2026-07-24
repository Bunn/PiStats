import PiStatsCore
import SwiftUI

struct WatchPiholeStatusView: View {
    let status: PiholeStatus
    let isRefreshing: Bool

    var body: some View {
        if isRefreshing && status == .unknown {
            Label {
                Text("Connecting")
            } icon: {
                ProgressView()
            }
            .foregroundStyle(.secondary)
        } else {
            Label(statusText, systemImage: statusImage)
                .foregroundStyle(statusColor)
        }
    }

    private var statusText: String {
        switch status {
        case .enabled:
            "Blocking active"
        case .disabled:
            "Blocking paused"
        case .unknown:
            "Status unavailable"
        }
    }

    private var statusImage: String {
        switch status {
        case .enabled:
            "checkmark.shield.fill"
        case .disabled:
            "pause.circle.fill"
        case .unknown:
            "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .enabled:
            .green
        case .disabled:
            .orange
        case .unknown:
            .secondary
        }
    }
}
