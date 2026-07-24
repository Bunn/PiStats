import SwiftUI

struct WatchAllBlockingControlView: View {
    let dashboard: WatchDashboardModel

    @State private var isShowingPauseOptions = false

    var body: some View {
        VStack(alignment: .leading, spacing: WatchDesign.contentSpacing) {
            HStack {
                Label("All Pi-holes", systemImage: "square.stack.3d.up.fill")
                    .font(.headline)

                Spacer()

                Text(dashboard.connectedPiholeCount, format: .number)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(
                        "\(dashboard.connectedPiholeCount) connected"
                    )
            }

            Group {
                if dashboard.isPerformingBulkAction {
                    ProgressView("Updating all")
                } else if dashboard.shouldResumeAll {
                    Button(
                        "Resume all",
                        systemImage: "play.circle.fill",
                        action: resumeAll
                    )
                    .tint(.green)
                } else {
                    Button(
                        "Pause all",
                        systemImage: "pause.circle.fill",
                        action: showPauseOptions
                    )
                    .tint(.orange)
                    .confirmationDialog(
                        "Pause blocking on all connected Pi-holes?",
                        isPresented: $isShowingPauseOptions
                    ) {
                        Button("For 5 minutes") {
                            pauseAll(for: 5 * 60)
                        }
                        Button("For 30 minutes") {
                            pauseAll(for: 30 * 60)
                        }
                        Button("For 1 hour") {
                            pauseAll(for: 60 * 60)
                        }
                        Button("Until I turn it back on", role: .destructive) {
                            pauseAll(for: nil)
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity, minHeight: 44)
        }
        .padding(WatchDesign.cardPadding)
        .background(
            WatchDesign.cardBackground,
            in: .rect(cornerRadius: WatchDesign.cardCornerRadius)
        )
        .sensoryFeedback(
            .success,
            trigger: dashboard.bulkActionCompletionID
        )
    }

    private func showPauseOptions() {
        isShowingPauseOptions = true
    }

    private func pauseAll(for seconds: Int?) {
        Task {
            await dashboard.pauseAll(timer: seconds)
        }
    }

    private func resumeAll() {
        Task {
            await dashboard.resumeAll()
        }
    }
}
