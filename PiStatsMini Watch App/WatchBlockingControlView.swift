import PiStatsCore
import SwiftUI

struct WatchBlockingControlView: View {
    let model: WatchPiholeModel

    @State private var isShowingPauseOptions = false

    var body: some View {
        Group {
            if model.isPerformingAction {
                ProgressView("Updating")
                    .frame(maxWidth: .infinity, minHeight: 44)
            } else if model.status == .enabled {
                Button(
                    "Pause blocking",
                    systemImage: "pause.circle.fill",
                    action: showPauseOptions
                )
                .tint(.orange)
                .confirmationDialog(
                    "Pause blocking on \(model.pihole.name)?",
                    isPresented: $isShowingPauseOptions
                ) {
                    Button("For 5 minutes") {
                        pause(for: 5 * 60)
                    }
                    Button("For 30 minutes") {
                        pause(for: 30 * 60)
                    }
                    Button("For 1 hour") {
                        pause(for: 60 * 60)
                    }
                    Button("Until I turn it back on", role: .destructive) {
                        pause(for: nil)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } else if model.status == .disabled {
                Button(
                    "Resume blocking",
                    systemImage: "play.circle.fill",
                    action: resume
                )
                .tint(.green)
            } else {
                Button(
                    "Refresh status",
                    systemImage: "arrow.clockwise",
                    action: refresh
                )
            }
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity, minHeight: 44)
        .sensoryFeedback(.success, trigger: model.actionCompletionID)
    }

    private func showPauseOptions() {
        isShowingPauseOptions = true
    }

    private func pause(for seconds: Int?) {
        Task {
            await model.disable(timer: seconds)
        }
    }

    private func resume() {
        Task {
            await model.enable()
        }
    }

    private func refresh() {
        Task {
            await model.refresh()
        }
    }
}
