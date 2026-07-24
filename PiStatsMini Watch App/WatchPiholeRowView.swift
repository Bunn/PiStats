import PiStatsCore
import SwiftUI

struct WatchPiholeRowView: View {
    let model: WatchPiholeModel

    var body: some View {
        VStack(alignment: .leading, spacing: WatchDesign.contentSpacing) {
            HStack(spacing: WatchDesign.contentSpacing) {
                Text(model.pihole.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }

            WatchPiholeStatusView(
                status: model.status,
                isRefreshing: model.isRefreshing
            )
            .font(.caption)

            HStack(spacing: WatchDesign.cardSpacing) {
                Label {
                    if let summary = model.summary {
                        Text(
                            summary.queries,
                            format: .number.notation(.compactName)
                        )
                    } else {
                        Text("—")
                    }
                } icon: {
                    Image(systemName: "network")
                }

                Spacer()

                Label {
                    if let summary = model.summary {
                        Text(
                            summary.adsPercentageToday / 100,
                            format: .percent.precision(.fractionLength(1))
                        )
                    } else {
                        Text("—")
                    }
                } icon: {
                    Image(systemName: "hand.raised.fill")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens Pi-hole details")
    }
}
