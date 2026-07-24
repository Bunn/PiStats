import SwiftUI
import Combine
import PiStatsCore

enum SecureTag: String, CaseIterable, Identifiable {
    case unsecure = "HTTP"
    case secure = "HTTPS"

    var id: String { self.rawValue }
}

@MainActor
fileprivate class SetupViewModel: ObservableObject {
    @Published var pihole: Pihole?
    @Published var host = ""
    @Published var port = ""
    @Published var password = ""
    @Published var displayName = ""
    @Published var showsSystemMetrics = false
    @Published var httpType: SecureTag = .unsecure
    
    private let storage = DefaultPiholeStorage()
    var onPiholeChanged: ((Pihole, Bool) -> Void)? // Bool indicates if it's a delete operation

    init(pihole: Pihole? = nil) {
        self.pihole = pihole

        if let pihole = pihole {
            self.displayName = pihole.name
            self.host = pihole.address
            self.port = "\(pihole.port)"
            self.password = pihole.password ?? ""
            self.httpType = pihole.secure ? .secure : .unsecure
            self.showsSystemMetrics = pihole.systemMetricsEnabled
        } else {
            self.port = "80" // Default port
        }
    }

    func savePihole() {
        let finalDisplayName = displayName.isEmpty ? host : displayName
        let finalPort = Int(port) ?? 80
        let finalPassword = password.isEmpty ? nil : password
        let isSecure = httpType == .secure
        
        let newPihole = Pihole(
            name: finalDisplayName,
            address: host,
            port: finalPort,
            secure: isSecure,
            password: finalPassword,
            systemMetricsEnabled: showsSystemMetrics,
            uuid: pihole?.uuid ?? UUID()
        )
        
        storage.savePihole(newPihole)
        onPiholeChanged?(newPihole, false)
    }
    
    func deletePihole() {
        guard let pihole = pihole else { return }
        storage.deletePihole(pihole)
        onPiholeChanged?(pihole, true)
    }
}

struct PiholeSetupView: View {
    @StateObject private var viewModel: SetupViewModel
    @Environment(\.dismiss) private var dismiss

    private let imageWidthSize: CGFloat = 20
    
    var onPiholeChanged: ((Pihole, Bool) -> Void)?

    init(pihole: Pihole? = nil, onPiholeChanged: ((Pihole, Bool) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: SetupViewModel(pihole: pihole))
        self.onPiholeChanged = onPiholeChanged
    }
    
    var body: some View {
        NavigationView {
            Form {
                piholeSettingsSection
                systemMetricsSettingsSection
                if viewModel.pihole != nil {
                    deleteSection
                }
            }
            .navigationTitle(UserText.piholeSetupTitle)
            .navigationBarItems(
                leading: Button(UserText.cancelButton, action: dismiss.callAsFunction),
                trailing: Button(UserText.saveButton, action: savePihole)
                    .disabled(!isFormValid)
            )
            .onAppear {
                viewModel.onPiholeChanged = onPiholeChanged
            }
        }
    }
    
    private var isFormValid: Bool {
        !viewModel.host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var piholeSettingsSection: some View {
        Section(
            header: Text(UserText.Settings.Sections.pihole),
            footer: Text(UserText.piholePasswordHelp)
        ) {
            LabeledTextField(
                icon: SystemImages.piholeSetupHost,
                placeholder: UserText.piholeSetupHostPlaceholder,
                text: $viewModel.host,
                width: imageWidthSize
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            LabeledTextField(
                icon: SystemImages.piholeSetupDisplayName,
                placeholder: UserText.piholeSetupDisplayName,
                text: $viewModel.displayName,
                width: imageWidthSize
            )
            .autocorrectionDisabled()

            LabeledTextField(
                icon: SystemImages.piholeSetupPort,
                placeholder: UserText.piholeSetupPortPlaceholder,
                text: $viewModel.port,
                width: imageWidthSize
            )
            .keyboardType(.numberPad)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Picker("", selection: $viewModel.httpType) {
                ForEach(SecureTag.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.palette)

            HStack {
                Image(systemName: SystemImages.piholeSetupPassword)
                    .frame(width: imageWidthSize)
                SecureField(UserText.piholePasswordPlaceholder, text: $viewModel.password)
            }
        }
    }

    private var systemMetricsSettingsSection: some View {
        Section {
            Toggle(isOn: $viewModel.showsSystemMetrics.animation()) {
                Label {
                    Text(UserText.showSystemMetrics)
                } icon: {
                    Image(systemName: SystemImages.piholeSetupMonitor)
                        .frame(width: imageWidthSize)
                }
            }

        } header: {
            Text(UserText.Settings.Sections.systemMetrics)
        } footer: {
            Text(UserText.systemMetricsDescription)
        }
    }

    private var deleteSection: some View {
        Section { EmptyView() } footer: { deleteButton }
    }

    private var deleteButton: some View {
        Button {
            viewModel.deletePihole()
            dismiss()
        } label: {
            Label(UserText.deleteButton, systemImage: SystemImages.deleteButton)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.defaultCornerRadius))
        }
    }

    private func savePihole() {
        viewModel.savePihole()
        dismiss()
    }
}

struct LabeledTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let width: CGFloat

    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: width)
            TextField(placeholder, text: $text)
        }
    }
}

#Preview {
    let mockPihole = Pihole(name: "test", address: "123.123.123.123")
    PiholeSetupView(pihole: mockPihole)
}
