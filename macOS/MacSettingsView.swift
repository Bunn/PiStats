import SwiftUI

struct MacSettingsView: View {
    @ObservedObject var prefs: MacPreferences
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack (alignment: .leading) {
                Picker("Temperature Scale", selection: $prefs.temperatureScale) {
                    ForEach(TemperatureScale.allCases, id: \.self) { scale in
                        Text(scale.displayName).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle(UserText.Settings.alwaysDisablePermanentlyToggle, isOn: $prefs.disablePermanently)
                    .toggleStyle(.switch)
                
                Toggle(UserText.Settings.startAtLoginToggle, isOn: $prefs.startAtLogin)
                    .toggleStyle(.switch)

            HStack {
                Spacer()
                Button(UserText.doneButton) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

#Preview {
    MacSettingsView(prefs: MacPreferences())
}
