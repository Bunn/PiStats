import WidgetKit
import SwiftUI
import PiStatsCore
import AppIntents

// MARK: - Pi Status Control Widget (Widget 3)

struct PiStatusControlWidget: Widget {
    let kind: String = "PiStatusControlWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, 
                             intent: PiholeSelectionIntent.self, 
                             provider: WidgetDataProvider()) { entry in
            PiStatusControlWidgetView(entry: entry)
        }
        .configurationDisplayName("Pi-hole Control")
        .description("View status and quickly enable/disable your Pi-hole")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Pi Status Control Widget View

struct PiStatusControlWidgetView: View {
    let entry: PiStatsEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with name and status
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.widgetData?.pihole.name ?? "Select Pi-hole")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    Spacer()
                }
                
                HStack {
                    StatusBadge(status: entry.widgetData?.status ?? .unknown)
                    Spacer()
                    Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Main content
            if let widgetData = entry.widgetData {
                VStack(spacing: 8) {
                    // Status display
                    VStack(spacing: 4) {
                        Image(systemName: statusIcon(for: widgetData.status))
                            .font(.system(size: 32))
                            .foregroundColor(statusColor(for: widgetData.status))
                        
                        Text(statusMessage(for: widgetData.status))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Control button
                    if widgetData.status != .unknown {
                        Button(intent: TogglePiholeIntent(piholeId: widgetData.pihole.uuid.uuidString)) {
                            HStack {
                                Image(systemName: buttonIcon(for: widgetData.status))
                                Text(buttonText(for: widgetData.status))
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(buttonColor(for: widgetData.status))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                // Placeholder state with layout but no data
                VStack(spacing: 8) {
                    VStack(spacing: 4) {
                        Image(systemName: statusIcon(for: .unknown))
                            .font(.system(size: 32))
                            .foregroundColor(statusColor(for: .unknown))
                        Text(statusMessage(for: .unknown))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    // No control button when state is unknown
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .widgetBackground {
            Color(.systemGroupedBackground)
        }
    }
    
    private func statusIcon(for status: PiholeStatus) -> String {
        switch status {
        case .enabled:
            return "checkmark.shield.fill"
        case .disabled:
            return "xmark.shield.fill"
        case .unknown:
            return "exclamationmark.shield.fill"
        }
    }
    
    private func statusColor(for status: PiholeStatus) -> Color {
        switch status {
        case .enabled:
            return AppColors.statusOnline
        case .disabled:
            return AppColors.statusOffline
        case .unknown:
            return AppColors.statusWarning
        }
    }
    
    private func statusMessage(for status: PiholeStatus) -> String {
        switch status {
        case .enabled:
            return "Pi-hole is actively blocking ads"
        case .disabled:
            return "Pi-hole is currently disabled"
        case .unknown:
            return "Unable to determine status"
        }
    }
    
    private func buttonText(for status: PiholeStatus) -> String {
        switch status {
        case .enabled:
            return "Disable"
        case .disabled:
            return "Enable"
        case .unknown:
            return "Refresh"
        }
    }
    
    private func buttonIcon(for status: PiholeStatus) -> String {
        switch status {
        case .enabled:
            return "stop.fill"
        case .disabled:
            return "play.fill"
        case .unknown:
            return "arrow.clockwise"
        }
    }
    
    private func buttonColor(for status: PiholeStatus) -> Color {
        switch status {
        case .enabled:
            return .red
        case .disabled:
            return .green
        case .unknown:
            return .blue
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: PiholeStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .enabled:
            return AppColors.statusOnline
        case .disabled:
            return AppColors.statusOffline
        case .unknown:
            return AppColors.statusWarning
        }
    }
    
    private var statusText: String {
        switch status {
        case .enabled:
            return "Active"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

// MARK: - Toggle Intent

struct TogglePiholeIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Pi-hole"
    static var description = IntentDescription("Enable or disable the Pi-hole")
    
    @Parameter(title: "Pi-hole ID")
    var piholeId: String
    
    init() {}
    
    init(piholeId: String) {
        self.piholeId = piholeId
    }
    
    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: piholeId),
              let pihole = widgetPiholeStorage.restorePihole(uuid) else {
            throw IntentError.message("Pi-hole not found")
        }
        
        let client = PiholeAPIClient(pihole)
        
        do {
            let currentStatus = try await client.fetchStatus()
            
            let newStatus: PiholeStatus
            if currentStatus == .enabled {
                newStatus = try await client.disable()
            } else {
                newStatus = try await client.enable()
            }
            
            // Refresh widget data
            WidgetCenter.shared.reloadTimelines(ofKind: "PiStatusControlWidget")
            
            let statusText = newStatus == .enabled ? "enabled" : "disabled"
            return .result(dialog: "Pi-hole has been \(statusText)")
            
        } catch {
            throw IntentError.message("Failed to toggle Pi-hole: \(error.localizedDescription)")
        }
    }
}

// MARK: - Intent Error

enum IntentError: Error, LocalizedError {
    case message(String)
    
    var errorDescription: String? {
        switch self {
        case .message(let message):
            return message
        }
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    PiStatusControlWidget()
} timeline: {
    PiStatsEntry.placeholder()
} 