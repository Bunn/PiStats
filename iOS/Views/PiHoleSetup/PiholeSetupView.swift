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
    let piMonitorURL = URL(string: "https://github.com/Bunn/pi_monitor")!

    @Published var pihole: Pihole?
    @Published var host = ""
    @Published var port = ""
    @Published var token = ""
    @Published var displayName = ""
    @Published var isShowingScanner = false
    @Published var piMonitorPort = ""
    @Published var isPiMonitorEnabled = false
    @Published var displayPiMonitorAlert = false
    @Published var httpType: SecureTag = .unsecure
    @Published var selectedVersion: PiholeVersion = .v6
    
    private let storage = DefaultPiholeStorage()
    var onPiholeChanged: ((Pihole, Bool) -> Void)? // Bool indicates if it's a delete operation

    init(pihole: Pihole? = nil) {
        self.pihole = pihole

        if let pihole = pihole {
            self.displayName = pihole.name
            self.host = pihole.address
            self.port = "\(pihole.port)"
            self.token = pihole.token ?? ""
            self.selectedVersion = pihole.version
            
            // Setup PiMonitor fields if available
            if let piMonitor = pihole.piMonitor {
                self.isPiMonitorEnabled = true
                self.piMonitorPort = "\(piMonitor.port ?? 8088)"
                self.httpType = piMonitor.secure ? .secure : .unsecure
            }
        } else {
            self.selectedVersion = .v6
            self.port = "80" // Default port
        }
    }

    func savePihole() {
        let finalDisplayName = displayName.isEmpty ? host : displayName
        let finalPort = Int(port) ?? 80
        let finalToken = token.isEmpty ? nil : token
        
        // Setup PiMonitor if enabled
        let piMonitor: PiMonitorEnvironment? = isPiMonitorEnabled ? 
            PiMonitorEnvironment(
                host: host,
                port: Int(piMonitorPort) ?? 8088,
                secure: httpType == .secure
            ) : nil
        
        let newPihole = Pihole(
            name: finalDisplayName,
            address: host,
            version: selectedVersion,
            port: finalPort,
            token: finalToken,
            piMonitor: piMonitor,
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
    @Environment(\.openURL) private var openURL
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
                piMonitorSettingsSection
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
            .sheet(isPresented: $viewModel.isShowingScanner) {
                scannerSheet
            }
            .alert(isPresented: $viewModel.displayPiMonitorAlert) {
                piMonitorAlert
            }
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
            footer: viewModel.selectedVersion == .v5 ? Text(UserText.piholeTokenFooterSection) : Text(UserText.piholeTokenFooterV6Section)
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

            Picker("", selection: $viewModel.selectedVersion) {
                ForEach(PiholeVersion.allCases) { version in
                    Text(version.userValue).tag(version)
                }
            }
            .pickerStyle(.palette)

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

            tokenField
        }
    }

    private var tokenField: some View {
        Group {
            if viewModel.selectedVersion == .v5 {
                HStack {
                    Image(systemName: SystemImages.piholeSetupToken)
                        .frame(width: imageWidthSize)
                    SecureField(UserText.piholeSetupTokenPlaceholder, text: $viewModel.token)
                    Image(systemName: SystemImages.piholeSetupTokenQRCode)
                        .foregroundStyle(.blue)
                        .onTapGesture { viewModel.isShowingScanner = true }
                }
            } else {
                HStack {
                    Image(systemName: SystemImages.piholeSetupToken)
                        .frame(width: imageWidthSize)
                    SecureField("Password", text: $viewModel.token)
                }
            }
        }
    }

    private var piMonitorSettingsSection: some View {
        Section(header: Text(UserText.Settings.Sections.piMonitor)) {
            Toggle(isOn: $viewModel.isPiMonitorEnabled.animation()) {
                HStack {
                    Image(systemName: SystemImages.piholeSetupMonitor)
                        .frame(width: imageWidthSize)
                    Text(UserText.piholeSetupEnablePiMonitor)
                        .lineLimit(1)
                    Image(systemName: SystemImages.piMonitorInfoButton)
                        .frame(width: imageWidthSize)
                        .foregroundStyle(.blue)
                        .onTapGesture { viewModel.displayPiMonitorAlert.toggle() }
                }
            }

            if viewModel.isPiMonitorEnabled {
                LabeledTextField(
                    icon: SystemImages.piholeSetupPort,
                    placeholder: UserText.piMonitorSetupPortPlaceholder,
                    text: $viewModel.piMonitorPort,
                    width: imageWidthSize
                )
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }
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

    private var scannerSheet: some View {
        NavigationView {
            CodeScannerView(codeTypes: [.qr], simulatedData: "abcd", completion: handleScan)
                .navigationTitle(UserText.qrCodeScannerTitle)
                .navigationBarItems(leading: Button(UserText.cancelButton) {
                    viewModel.isShowingScanner = false
                })
        }
    }

    private var piMonitorAlert: Alert {
        Alert(
            title: Text(UserText.piMonitorSetupAlertTitle),
            message: Text(UserText.piMonitorExplanation),
            primaryButton: .default(Text(UserText.piMonitorSetupAlertLearnMoreButton)) {
                openURL(viewModel.piMonitorURL)
            },
            secondaryButton: .cancel(Text(UserText.piMonitorSetupAlertOKButton))
        )
    }

    private func savePihole() {
        viewModel.savePihole()
        dismiss()
    }

    private func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        viewModel.isShowingScanner = false
        if case .success(let data) = result {
            handleScannedString(data)
        }
    }

    private func handleScannedString(_ value: String) {
        guard let data = value.data(using: .utf8),
              let result = try? JSONDecoder().decode([String: ScannedPihole].self, from: data),
              let scannedPihole = result["pihole"]
        else {
            viewModel.token = value
            return
        }

        viewModel.token = scannedPihole.token ?? ""
        viewModel.host = scannedPihole.host
        viewModel.port = String(scannedPihole.port)
        viewModel.httpType = scannedPihole.secure ?? false ? .secure : .unsecure
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
    let mockPihole = Pihole(name: "test", address: "123.123.123.123", version: .v5)
    PiholeSetupView(pihole: mockPihole)
}

struct ScannedPihole: Codable {
    let host: String
    let port: Int
    let token: String?
    let secure: Bool?
}
