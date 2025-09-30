import WidgetKit
import SwiftUI
import PiStatsCore
import AppIntents

// MARK: - Constants

private struct WidgetConstants {
    struct Layout {
        static let centerShieldSize: CGFloat = 40
        static let statusIndicatorSize: CGFloat = 8
        static let shadowRadius: CGFloat = 3
        static let shadowOffset: CGSize = CGSize(width: 0, height: 1)
    }
    
    struct Typography {
        static let centerShieldIconSize: CGFloat = 24
        static let statIconSizeSmall: CGFloat = 16
        static let statIconSizeMedium: CGFloat = 14
        static let statValueSizeSmall: CGFloat = 18
        static let statValueSizeMedium: CGFloat = 16
        static let statTitleSize: CGFloat = 15
    }
    
    struct Spacing {
        static let cardContentVertical: CGFloat = 6
        static let cardContentHorizontal: CGFloat = 16
        static let statCardVertical: CGFloat = 6
        static let statCardHorizontal: CGFloat = 6
        static let statusIndicatorHorizontal: CGFloat = 4
        static let titleSpacing: CGFloat = 4
    }
    
    struct Opacity {
        static let shadowOpacity: Double = 0.1
        static let titleOpacity: Double = 0.8
    }
    
    struct Scale {
        static let titleMinimumScale: CGFloat = 0.6
        static let valueMinimumScale: CGFloat = 0.7
    }
}

// MARK: - Pi Stats Overview Widget

struct PiStatsOverviewWidget: Widget {
    let kind: String = "ViewStatsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PiholeSelectionIntent.self,
            provider: WidgetDataProvider()
        ) { entry in
            PiStatsOverviewWidgetView(entry: entry)
        }
        .configurationDisplayName("Pi-hole Stats")
        .description("View all Pi-hole statistics at a glance")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Pi Stats Overview Widget View

struct PiStatsOverviewWidgetView: View {
    let entry: PiStatsEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let widgetData = entry.widgetData {
                if let summary = widgetData.summary {
                    buildStatsView(summary: summary, status: widgetData.status)
                } else {
                    buildPlaceholderView(status: widgetData.status)
                }
            } else {
                buildPlaceholderView(status: .unknown)
            }
        }
        .widgetBackground {
            Color(.systemGroupedBackground)
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func buildStatsView(summary: PiholeSummary, status: PiholeStatus) -> some View {
        ZStack {
            buildStatsGrid(summary: summary)
            CenterShield(status: status)
        }
    }
    
    @ViewBuilder
    private func buildStatsGrid(summary: PiholeSummary) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatCard(
                    value: formatCompactNumber(summary.queries),
                    color: AppColors.totalQueries,
                    icon: SystemImages.totalQueries,
                    title: family == .systemMedium ? "Total Queries" : nil
                )
                
                StatCard(
                    value: formatCompactNumber(summary.adsBlocked),
                    color: AppColors.queriesBlocked,
                    icon: SystemImages.queriesBlocked,
                    title: family == .systemMedium ? "Blocked" : nil
                )
            }
            
            HStack(spacing: 0) {
                StatCard(
                    value: String(format: "%.1f%%", summary.adsPercentageToday),
                    color: AppColors.percentBlocked,
                    icon: SystemImages.percentBlocked,
                    title: family == .systemMedium ? "Blocked %" : nil
                )
                
                StatCard(
                    value: formatCompactNumber(summary.domainsBeingBlocked),
                    color: AppColors.domainsOnBlocklist,
                    icon: SystemImages.domainsOnBlockList,
                    title: family == .systemMedium ? "Blocklist" : nil
                )
            }
        }
    }
    
    @ViewBuilder
    private func buildPlaceholderView(status: PiholeStatus) -> some View {
        ZStack {
            buildPlaceholderGrid()
            CenterShield(status: status)
        }
    }
    
    @ViewBuilder
    private func buildPlaceholderGrid() -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                StatCard(
                    value: "—",
                    color: AppColors.totalQueries,
                    icon: SystemImages.totalQueries,
                    title: family == .systemMedium ? "Total Queries" : nil
                )
                
                StatCard(
                    value: "—",
                    color: AppColors.queriesBlocked,
                    icon: SystemImages.queriesBlocked,
                    title: family == .systemMedium ? "Blocked" : nil
                )
            }
            
            HStack(spacing: 0) {
                StatCard(
                    value: "—",
                    color: AppColors.percentBlocked,
                    icon: SystemImages.percentBlocked,
                    title: family == .systemMedium ? "Blocked %" : nil
                )
                
                StatCard(
                    value: "—",
                    color: AppColors.domainsOnBlocklist,
                    icon: SystemImages.domainsOnBlockList,
                    title: family == .systemMedium ? "Blocklist" : nil
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Formats numbers using compact notation for better readability
    private func formatCompactNumber(_ number: Int) -> String {
        let num = Double(number)
        return num.formatted(.number.notation(.automatic))
    }
}

// MARK: - Center Shield

struct CenterShield: View {
    let status: PiholeStatus

    var body: some View {
        ZStack {
            buildBackgroundCircle()
            buildShieldIcon()
        }
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func buildBackgroundCircle() -> some View {
        Circle()
            .fill(Color(.systemGroupedBackground))
            .frame(
                width: WidgetConstants.Layout.centerShieldSize,
                height: WidgetConstants.Layout.centerShieldSize
            )
            .shadow(
                color: .black.opacity(WidgetConstants.Opacity.shadowOpacity),
                radius: WidgetConstants.Layout.shadowRadius,
                x: WidgetConstants.Layout.shadowOffset.width,
                y: WidgetConstants.Layout.shadowOffset.height
            )
    }
    
    @ViewBuilder
    private func buildShieldIcon() -> some View {
        Image(systemName: shieldImageName)
            .font(.system(size: WidgetConstants.Typography.centerShieldIconSize))
            .foregroundColor(shieldColor)
    }
    
    // MARK: - Computed Properties
    
    private var shieldImageName: String {
        switch status {
        case .enabled:
            return "checkmark.shield.fill"
        case .disabled:
            return "xmark.shield.fill"
        case .unknown:
            return "exclamationmark.shield.fill"
        }
    }

    private var shieldColor: Color {
        switch status {
        case .enabled:
            return AppColors.statusOnline
        case .disabled:
            return AppColors.statusOffline
        case .unknown:
            return AppColors.statusWarning
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let value: String
    let color: Color
    let icon: String
    let title: String?

    var body: some View {
        ZStack {
            color
            
            if let title = title {
                buildMediumFamilyLayout(title: title)
            } else {
                buildSmallFamilyLayout()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - View Builders
    
    @ViewBuilder
    private func buildMediumFamilyLayout(title: String) -> some View {
        VStack(alignment: .leading, spacing: WidgetConstants.Spacing.titleSpacing) {
            HStack {
                Text(title)
                    .font(.system(
                        size: WidgetConstants.Typography.statTitleSize,
                        weight: .medium
                    ))
                    .foregroundColor(.white.opacity(WidgetConstants.Opacity.titleOpacity))
                    .lineLimit(1)
                    .minimumScaleFactor(WidgetConstants.Scale.titleMinimumScale)
                Spacer()
            }
            
            HStack(spacing: WidgetConstants.Spacing.statCardHorizontal) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: WidgetConstants.Typography.statIconSizeMedium))

                Text(value)
                    .font(.system(
                        size: WidgetConstants.Typography.statValueSizeMedium,
                        weight: .bold,
                        design: .rounded
                    ))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(WidgetConstants.Scale.valueMinimumScale)
                
                Spacer()
            }
        }
        .padding(.horizontal, WidgetConstants.Spacing.cardContentHorizontal)
        .padding(.vertical, WidgetConstants.Spacing.cardContentVertical)
    }
    
    @ViewBuilder
    private func buildSmallFamilyLayout() -> some View {
        VStack(spacing: WidgetConstants.Spacing.statCardVertical) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: WidgetConstants.Typography.statIconSizeSmall))

            Text(value)
                .font(.system(
                    size: WidgetConstants.Typography.statValueSizeSmall,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(WidgetConstants.Scale.valueMinimumScale)
        }
    }
}

// MARK: - Status Indicator

struct StatusIndicator: View {
    let status: PiholeStatus

    var body: some View {
        HStack(spacing: WidgetConstants.Spacing.statusIndicatorHorizontal) {
            Circle()
                .fill(statusColor)
                .frame(
                    width: WidgetConstants.Layout.statusIndicatorSize,
                    height: WidgetConstants.Layout.statusIndicatorSize
                )

            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Computed Properties

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

// MARK: - Preview

#Preview(as: .systemMedium) {
    PiStatsOverviewWidget()
} timeline: {
    PiStatsEntry.placeholder()
}
