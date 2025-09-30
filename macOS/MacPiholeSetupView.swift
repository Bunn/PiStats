import SwiftUI
import PiStatsCore

private enum MacSecureTag: String, CaseIterable, Identifiable {
    case http = "HTTP"
    case https = "HTTPS"
    var id: String { rawValue }
}

@MainActor
private final class MacPiholeSetupViewModel: ObservableObject {
    @Published var pihole: Pihole?
    @Published var host = ""
    @Published var port = ""
    @Published var token = ""
    @Published var displayName = ""
    @Published var piMonitorPort = ""
    @Published var isPiMonitorEnabled = false
    @Published var httpType: MacSecureTag = .http
    @Published var selectedVersion: PiholeVersion = .v6

    private let storage = DefaultPiholeStorage()

    var isFormValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

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
                self.httpType = piMonitor.secure ? .https : .http
            }
        } else {
            self.selectedVersion = .v6
            self.port = "80" // Default port
        }
    }

    func save() -> Pihole {
        let finalDisplayName = displayName.isEmpty ? host : displayName
        let finalPort = Int(port) ?? 80
        let finalToken = token.isEmpty ? nil : token

        let piMonitor: PiMonitorEnvironment? = isPiMonitorEnabled ?
            PiMonitorEnvironment(
                host: host,
                port: Int(piMonitorPort) ?? 8088,
                secure: httpType == .https
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
        return newPihole
    }
}

struct MacPiholeSetupView: View {
    @StateObject private var viewModel: MacPiholeSetupViewModel
    @Environment(\.dismiss) private var dismiss

    var onPiholeChanged: ((Pihole, Bool) -> Void)?

    init(pihole: Pihole? = nil, onPiholeChanged: ((Pihole, Bool) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: MacPiholeSetupViewModel(pihole: pihole))
        self.onPiholeChanged = onPiholeChanged
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            headerView
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                piholeConfigurationSection
                piMonitorConfigurationSection
                
                if viewModel.pihole != nil {
                    Divider()
                    deleteSection
                }
            }
            .padding(16)
            
            Spacer()
            
            // Footer with buttons
            footerView
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(viewModel.pihole == nil ? UserText.Setup.addPiholeTitle : UserText.Setup.editPiholeTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(UserText.cancelButton) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Footer
    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Spacer()
                
                Button(UserText.cancelButton) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button(UserText.saveButton) {
                    saveAndClose()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.isFormValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Pi-hole Configuration
    private var piholeConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(UserText.Setup.piholeConfigurationSection)
            
            VStack(alignment: .leading, spacing: 15) {
                macOSTextField(
                    title: UserText.Setup.hostLabel,
                    placeholder: UserText.Setup.hostPlaceholder,
                    text: $viewModel.host
                )
                
                macOSTextField(
                    title: UserText.Setup.displayNameLabel,
                    placeholder: UserText.Setup.displayNamePlaceholder,
                    text: $viewModel.displayName
                )
                
                Picker("Version", selection: $viewModel.selectedVersion) {
                    ForEach(PiholeVersion.allCases) { version in
                        Text(version.userValue).tag(version)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Protocol", selection: $viewModel.httpType) {
                    ForEach(MacSecureTag.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                macOSTextField(
                    title: UserText.Setup.portLabel,
                    placeholder: UserText.Setup.portPlaceholder,
                    text: $viewModel.port
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.selectedVersion == .v5 ? UserText.Setup.apiTokenLabel : UserText.Setup.passwordLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField(
                        viewModel.selectedVersion == .v5 ? UserText.Setup.apiTokenPlaceholder : UserText.Setup.passwordPlaceholder,
                        text: $viewModel.token
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    Text(viewModel.selectedVersion == .v5 ? 
                         UserText.Setup.apiTokenHelp :
                         UserText.Setup.passwordHelp)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Pi Monitor Configuration
    private var piMonitorConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(UserText.Setup.piMonitorOptionalSection)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Toggle(UserText.Setup.enablePiMonitorLabel, isOn: $viewModel.isPiMonitorEnabled)
                        .toggleStyle(.switch)
                    
                    Spacer()
                    
                    Button(UserText.Setup.whatsThisButton) {
                        showPiMonitorInfo()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .font(.caption)
                }
                
                if viewModel.isPiMonitorEnabled {
                    macOSTextField(
                        title: UserText.Setup.portLabel,
                        placeholder: UserText.Setup.piMonitorPortPlaceholder,
                        text: $viewModel.piMonitorPort
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.isPiMonitorEnabled)
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Delete Section
    private var deleteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(UserText.Setup.dangerZoneSection)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.Setup.deletePiholeLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(UserText.Setup.deletePiholeDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(UserText.deleteButton) {
                    deletePihole()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
    }
    
    private func macOSTextField(title: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // MARK: - Actions
    private func saveAndClose() {
        let saved = viewModel.save()
        onPiholeChanged?(saved, false)
        dismiss()
    }
    
    private func deletePihole() {
        guard let pihole = viewModel.pihole else { return }
        let storage = DefaultPiholeStorage()
        storage.deletePihole(pihole)
        onPiholeChanged?(pihole, true)
        dismiss()
    }
    
    private func showPiMonitorInfo() {
        let alert = NSAlert()
        alert.messageText = UserText.Setup.piMonitorInfoTitle
        alert.informativeText = UserText.Setup.piMonitorInfoMessage
        alert.addButton(withTitle: UserText.Setup.learnMoreButton)
        alert.addButton(withTitle: UserText.Setup.okButton)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            if let url = URL(string: UserText.Setup.piMonitorURL) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

#Preview {
    MacPiholeSetupView()
}
