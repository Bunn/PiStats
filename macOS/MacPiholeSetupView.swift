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
    @Published var password = ""
    @Published var displayName = ""
    @Published var showsSystemMetrics = false
    @Published var httpType: MacSecureTag = .http

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
            self.password = pihole.password ?? ""
            self.httpType = pihole.secure ? .https : .http
            self.showsSystemMetrics = pihole.systemMetricsEnabled
        } else {
            self.port = "80" // Default port
        }
    }

    func save() -> Pihole {
        let finalDisplayName = displayName.isEmpty ? host : displayName
        let finalPort = Int(port) ?? 80
        let finalPassword = password.isEmpty ? nil : password
        let isSecure = httpType == .https

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
                systemMetricsConfigurationSection
                
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
                
                HStack {
                    Text("Protocol")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Picker("", selection: $viewModel.httpType) {
                        ForEach(MacSecureTag.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .fixedSize()
                }
                
                macOSTextField(
                    title: UserText.Setup.portLabel,
                    placeholder: UserText.Setup.portPlaceholder,
                    text: $viewModel.port
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(UserText.Setup.passwordLabel)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField(
                        UserText.Setup.passwordPlaceholder,
                        text: $viewModel.password
                    )
                    .textFieldStyle(.roundedBorder)
                    
                    Text(UserText.Setup.passwordHelp)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
    
    // MARK: - System Metrics Configuration
    private var systemMetricsConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(UserText.Setup.systemMetricsSection)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(UserText.showSystemMetrics)

                    Spacer()

                    Toggle("", isOn: $viewModel.showsSystemMetrics)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                Text(UserText.systemMetricsDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
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
    
}

#Preview {
    MacPiholeSetupView()
}
