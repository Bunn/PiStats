import SwiftUI

struct WatchPiholeCardView: View {
    let model: WatchPiholeModel

    var body: some View {
        VStack(alignment: .leading, spacing: WatchDesign.cardSpacing) {
            NavigationLink(value: model.id) {
                WatchPiholeRowView(model: model)
            }
            .buttonStyle(.plain)

            Divider()

            WatchBlockingControlView(model: model)
        }
        .padding(WatchDesign.cardPadding)
        .background(
            WatchDesign.cardBackground,
            in: .rect(cornerRadius: WatchDesign.cardCornerRadius)
        )
    }
}
