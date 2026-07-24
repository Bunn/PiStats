import SwiftUI

struct WatchEmptyStateView: View {
    let message: String
    let isSyncing: Bool
    let syncAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: WatchDesign.cardSpacing) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Text("Settings needed")
                    .font(.headline)

                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button(
                    "Fetch settings",
                    systemImage: "arrow.triangle.2.circlepath",
                    action: syncAction
                )
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(isSyncing)

                if isSyncing {
                    ProgressView()
                        .accessibilityLabel("Fetching Pi-hole settings")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, WatchDesign.screenPadding)
        }
    }
}
