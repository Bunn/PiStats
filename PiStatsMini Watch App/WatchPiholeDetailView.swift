import PiStatsCore
import SwiftUI

struct WatchPiholeDetailView: View {
    let model: WatchPiholeModel

    private let columns = [
        GridItem(.flexible(), spacing: WatchDesign.cardSpacing),
        GridItem(.flexible(), spacing: WatchDesign.cardSpacing)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: WatchDesign.cardSpacing) {
                WatchPiholeStatusView(
                    status: model.status,
                    isRefreshing: model.isRefreshing
                )

                WatchBlockingControlView(model: model)

                LazyVGrid(
                    columns: columns,
                    spacing: WatchDesign.cardSpacing
                ) {
                    WatchMetricView(
                        title: "Total queries",
                        value: model.summary.map {
                            $0.queries.formatted(.number.notation(.compactName))
                        } ?? "—",
                        systemImage: "network",
                        tint: .blue
                    )

                    WatchMetricView(
                        title: "Blocked",
                        value: model.summary.map {
                            $0.adsBlocked.formatted(.number.notation(.compactName))
                        } ?? "—",
                        systemImage: "hand.raised.fill",
                        tint: .orange
                    )

                    WatchMetricView(
                        title: "Percent blocked",
                        value: model.summary.map {
                            ($0.adsPercentageToday / 100).formatted(
                                .percent.precision(.fractionLength(1))
                            )
                        } ?? "—",
                        systemImage: "chart.pie.fill",
                        tint: .purple
                    )

                    WatchMetricView(
                        title: "Domains on list",
                        value: model.summary.map {
                            $0.domainsBeingBlocked.formatted(
                                .number.notation(.compactName)
                            )
                        } ?? "—",
                        systemImage: "list.bullet.rectangle.fill",
                        tint: .pink
                    )
                }

                if let lastUpdated = model.lastUpdated {
                    Text("Updated \(lastUpdated, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, WatchDesign.screenPadding)
            .padding(.bottom, WatchDesign.cardSpacing)
        }
        .navigationTitle(model.pihole.name)
        .task {
            await model.refresh()
        }
    }
}
