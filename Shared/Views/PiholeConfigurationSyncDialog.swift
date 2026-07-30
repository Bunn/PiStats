import SwiftUI

extension View {
    func piholeConfigurationSyncDialog<Item>(
        pendingChange: Binding<Item?>,
        options: PiholeConfigurationSyncOptions,
        perform: @escaping (Item, PiholeConfigurationChangeScope) -> Void
    ) -> some View {
        modifier(
            PiholeConfigurationSyncDialogModifier(
                pendingChange: pendingChange,
                options: options,
                perform: perform
            )
        )
    }
}

private struct PiholeConfigurationSyncDialogModifier<Item>: ViewModifier {
    @Binding var pendingChange: Item?
    let options: PiholeConfigurationSyncOptions
    let perform: (Item, PiholeConfigurationChangeScope) -> Void

    func body(content: Content) -> some View {
#if os(iOS)
        content
            .alert(
                UserText.configurationSyncDialogTitle,
                isPresented: isPresented
            ) {
                Button(UserText.configurationSyncCurrentPihole) {
                    performPendingChange(scope: .currentPihole)
                }
                Button(UserText.configurationSyncAllPiholes) {
                    performPendingChange(scope: .allPiholes)
                }
                Button(UserText.cancelButton, role: .cancel) {
                    pendingChange = nil
                }
            } message: {
                Text(UserText.configurationSyncDialogMessage)
            }
#else
        content
            .confirmationDialog(
                UserText.configurationSyncDialogTitle,
                isPresented: isPresented,
                titleVisibility: .visible
            ) {
                Button(UserText.configurationSyncCurrentPihole) {
                    performPendingChange(scope: .currentPihole)
                }
                Button(UserText.configurationSyncAllPiholes) {
                    performPendingChange(scope: .allPiholes)
                }
                Button(UserText.cancelButton, role: .cancel) {
                    pendingChange = nil
                }
            } message: {
                Text(UserText.configurationSyncDialogMessage)
            }
#endif
    }

    private var isPresented: Binding<Bool> {
        Binding(
            get: { pendingChange != nil },
            set: { newValue in
                if !newValue {
                    pendingChange = nil
                }
            }
        )
    }

    private func performPendingChange(scope: PiholeConfigurationChangeScope) {
        guard let change = pendingChange else { return }
        pendingChange = nil
        perform(change, scope)
    }
}
