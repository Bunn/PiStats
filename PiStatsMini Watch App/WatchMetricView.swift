import SwiftUI

struct WatchMetricView: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: WatchDesign.contentSpacing) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(value)
                .font(.title3)
                .bold()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(
                    maxWidth: .infinity,
                    minHeight: WatchDesign.metricTitleHeight,
                    alignment: .topLeading
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(WatchDesign.cardPadding)
        .background(
            WatchDesign.cardBackground,
            in: .rect(cornerRadius: WatchDesign.cardCornerRadius)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}
