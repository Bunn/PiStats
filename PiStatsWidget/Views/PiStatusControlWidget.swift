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
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Pi Status Control Widget View

struct PiStatusControlWidgetView: View {
    let entry: PiStatsEntry
    @Environment(\.widgetFamily) private var family

    private var status: PiholeStatus {
        entry.widgetData?.status ?? .unknown
    }

    var body: some View {
        Group {
            if family == .systemMedium {
                mediumLayout
            } else {
                smallLayout
            }
        }
        .widgetBackground {
            backgroundGradient
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ContainerRelativeShape()
            .fill(
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var gradientColors: [Color] {
        switch status {
        case .enabled:
            return [
                Color(.systemBackground),
                AppColors.statusOnline.opacity(0.08)
            ]
        case .disabled:
            return [
                Color(.systemBackground),
                AppColors.statusOffline.opacity(0.08)
            ]
        case .unknown:
            return [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ]
        }
    }

    // MARK: - Small Layout

    private var smallLayout: some View {
        VStack(spacing: 0) {
            headerView

            Spacer()

            Image(systemName: shieldIcon)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(statusColor)
                .symbolRenderingMode(.hierarchical)

            Text(statusLabel)
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundStyle(statusColor)
                .padding(.top, 2)

            Spacer()

            if let widgetData = entry.widgetData, status != .unknown {
                toggleButton(for: widgetData, expanded: true)
            }

            updatedTimestamp
        }
        .padding(16)
    }

    // MARK: - Medium Layout

    private var mediumLayout: some View {
        VStack(spacing: 0) {
            headerView
                .padding(.horizontal, 16)
                .padding(.top, 16)

            Spacer(minLength: 0)

            HStack(spacing: 0) {
                // Left: status info
                HStack(spacing: 12) {
                    Image(systemName: shieldIcon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(statusColor)
                        .symbolRenderingMode(.hierarchical)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(statusLabel)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        Text(statusDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: 0)

                // Right: action
                if let widgetData = entry.widgetData, status != .unknown {
                    toggleButton(for: widgetData, expanded: false)
                }
            }
            .padding(.horizontal, 16)

            Spacer(minLength: 0)

            updatedTimestamp
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        VStack(spacing: 6) {
            HStack(alignment: .top) {
                Text(entry.widgetData?.pihole.name ?? "Pi-hole")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .foregroundStyle(.secondary)
            }
            Divider()
                .padding(.horizontal, -16)
        }
    }

    private var updatedTimestamp: some View {
        Text("Updated \(entry.date.formatted(date: .omitted, time: .shortened))")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.top, 6)
    }

    // MARK: - Toggle Button

    @ViewBuilder
    private func toggleButton(for widgetData: WidgetData, expanded: Bool) -> some View {
        Button(intent: TogglePiholeIntent(piholeId: widgetData.pihole.uuid.uuidString)) {
            Label(buttonLabel, systemImage: buttonIcon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(buttonTint)
                .frame(maxWidth: expanded ? .infinity : nil)
                .padding(.horizontal, expanded ? 0 : 20)
                .padding(.vertical, 10)
                .background(buttonTint.opacity(0.12))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Status Helpers

    private var shieldIcon: String {
        switch status {
        case .enabled: "checkmark.shield.fill"
        case .disabled: "xmark.shield.fill"
        case .unknown: "questionmark.shield.fill"
        }
    }

    private var statusColor: Color {
        switch status {
        case .enabled: AppColors.statusOnline
        case .disabled: AppColors.statusOffline
        case .unknown: .secondary
        }
    }

    private var statusLabel: String {
        switch status {
        case .enabled: "Protected"
        case .disabled: "Unprotected"
        case .unknown: "Unavailable"
        }
    }

    private var statusDescription: String {
        switch status {
        case .enabled: "Blocking ads & trackers"
        case .disabled: "Ad blocking is paused"
        case .unknown: "Unable to connect"
        }
    }

    private var buttonLabel: String {
        switch status {
        case .enabled: "Disable"
        case .disabled: "Enable"
        case .unknown: "Retry"
        }
    }

    private var buttonIcon: String {
        switch status {
        case .enabled: "pause.fill"
        case .disabled: "play.fill"
        case .unknown: "arrow.clockwise"
        }
    }

    private var buttonTint: Color {
        switch status {
        case .enabled: AppColors.statusOffline
        case .disabled: AppColors.statusOnline
        case .unknown: .secondary
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

#Preview(as: .systemMedium) {
    PiStatusControlWidget()
} timeline: {
    PiStatsEntry.placeholder()
}