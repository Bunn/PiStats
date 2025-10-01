import WidgetKit
import SwiftUI
import PiStatsCore
import AppIntents

// MARK: - Constants

private enum Constants {
    enum Layout {
        static let mainSpacing: CGFloat = 8
        static let metricSpacing: CGFloat = 6
        static let iconWidth: CGFloat = 16
    }
    
    enum Temperature {
        static let highThreshold: Double = 70
        static let mediumThreshold: Double = 60
    }
    
    enum Memory {
        static let highThreshold: Double = 80
        static let mediumThreshold: Double = 60
    }
    
    enum LoadAverage {
        static let highThreshold: Double = 2.0
        static let mediumThreshold: Double = 1.0
    }
    
    enum Formatting {
        static let temperatureMaxFractionDigits = 1
        static let percentageSignificantDigits = 2
        static let loadAverageFormat = "%.2f"
    }
}

// MARK: - Pi Monitor Widget

struct PiMonitorWidget: Widget {
    let kind: String = "PiMonitorWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: PiholeSelectionIntent.self,
            provider: WidgetDataProvider()
        ) { entry in
            PiMonitorWidgetView(entry: entry)
        }
        .configurationDisplayName("Pi Monitor")
        .description("Monitor your Raspberry Pi's system metrics")
        .contentMarginsDisabled()
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Settings

struct WidgetSettings {
    static var temperatureScale: TemperatureScale {
        let sharedDefaults = UserDefaults.shared()
        
        // Use device's locale as default if never set, same as main app
        guard sharedDefaults.object(forKey: "temperatureScale") != nil else {
            let defaultScale: TemperatureScale = Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
            return defaultScale
        }
        
        let rawValue = sharedDefaults.integer(forKey: "temperatureScale")
        return TemperatureScale(rawValue: rawValue) ?? .celsius
    }
}

// MARK: - Temperature Scale

enum TemperatureScale: Int, CaseIterable {
    case celsius = 0
    case fahrenheit = 1
}

// MARK: - Widget Metric Item View Model

struct WidgetMetricItemViewModel {
    // MARK: Properties
    
    private let metrics: PiMonitorMetrics
    private let temperatureScale: TemperatureScale
    
    // MARK: Initialization
    
    init(metrics: PiMonitorMetrics, temperatureScale: TemperatureScale = .celsius) {
        self.metrics = metrics
        self.temperatureScale = temperatureScale
    }
    
    // MARK: Computed Properties
    
    var temperature: String {
        let temperatureValue = Measurement(value: metrics.socTemperature, unit: UnitTemperature.celsius)
        let measurementFormatter = createTemperatureFormatter()
        
        let targetUnit: UnitTemperature = temperatureScale == .celsius ? .celsius : .fahrenheit
        let convertedTemperature = temperatureValue.converted(to: targetUnit)
        return measurementFormatter.string(from: convertedTemperature)
    }
    
    var uptime: String {
        let uptimeDuration = Duration.seconds(metrics.uptime)
        return uptimeDuration.formatted(.units(allowed: [.days, .hours, .minutes], width: .narrow))
    }
    
    var loadAverage: String {
        guard !metrics.loadAverage.isEmpty else { return "N/A" }
        return String(format: Constants.Formatting.loadAverageFormat, metrics.loadAverage[0])
    }
    
    var memoryUsage: String {
        let usedMemory = metrics.memory.totalMemory - metrics.memory.availableMemory
        let percentageUsed = Double(usedMemory) / Double(metrics.memory.totalMemory)
        return percentageUsed.formatted(.percent.precision(.significantDigits(Constants.Formatting.percentageSignificantDigits)))
    }
    
    // MARK: Private Methods
    
    private func createTemperatureFormatter() -> MeasurementFormatter {
        let formatter = MeasurementFormatter()
        formatter.locale = Locale.current
        formatter.unitOptions = .providedUnit
        formatter.numberFormatter.maximumFractionDigits = Constants.Formatting.temperatureMaxFractionDigits
        return formatter
    }
}

// MARK: - Pi Monitor Widget View

struct PiMonitorWidgetView: View {
    let entry: PiStatsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Layout.mainSpacing) {
            headerView
            Divider()
            contentView
        }
        .padding()
        .widgetBackground {
            Color(.systemGroupedBackground)
        }
    }
    
    // MARK: Private Views
    
    private var headerView: some View {
        HStack {
            Text(entry.widgetData?.pihole.name ?? "Select Pi-hole")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
            Spacer()
            Image(systemName: SystemImages.piholeSetupMonitor)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        if let metrics = entry.widgetData?.monitorMetrics {
            metricsView(for: metrics)
        } else if let widgetData = entry.widgetData {
            placeholderMetricsView(status: widgetData.status)
        } else {
            placeholderMetricsView(status: .unknown)
        }
    }
    
    private func metricsView(for metrics: PiMonitorMetrics) -> some View {
        let viewModel = WidgetMetricItemViewModel(
            metrics: metrics,
            temperatureScale: WidgetSettings.temperatureScale
        )
        
        return VStack(spacing: Constants.Layout.metricSpacing) {
            MetricRow(
                icon: SystemImages.metricTemperature,
                title: "Temperature",
                value: viewModel.temperature,
                color: .domainsOnBlockList
            )
            
            MetricRow(
                icon: SystemImages.metricMemoryUsage,
                title: "Memory",
                value: viewModel.memoryUsage,
                color: .totalQueries
            )
            
            MetricRow(
                icon: SystemImages.metricLoadAverage,
                title: "Load",
                value: viewModel.loadAverage,
                color: .percentBlocked
            )
            
            MetricRow(
                icon: SystemImages.metricUptime,
                title: "Uptime",
                value: viewModel.uptime,
                color: .queriesBlocked
            )
        }
    }
    
    private func placeholderMetricsView(status: PiholeStatus) -> some View {
        VStack(spacing: Constants.Layout.metricSpacing) {
            MetricRow(
                icon: SystemImages.metricTemperature,
                title: "Temperature",
                value: "—",
                color: .domainsOnBlockList
            )
            
            MetricRow(
                icon: SystemImages.metricMemoryUsage,
                title: "Memory",
                value: "—",
                color: .totalQueries
            )
            
            MetricRow(
                icon: SystemImages.metricLoadAverage,
                title: "Load",
                value: "—",
                color: .percentBlocked
            )
            
            MetricRow(
                icon: SystemImages.metricUptime,
                title: "Uptime",
                value: "—",
                color: .queriesBlocked
            )
        }
    }
}

// MARK: - Metric Row

struct MetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
                .frame(width: Constants.Layout.iconWidth)
            
            if widgetFamily == .systemMedium {
                Text(title)
                    .font(Font.body.weight(.medium))
                    .minimumScaleFactor(0.80)
                    .foregroundColor(color)
            }
            
            Spacer()
            
            Text(value)
                .font(Font.body.weight(.medium))
                .minimumScaleFactor(0.80)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemMedium) {
    PiMonitorWidget()
} timeline: {
    PiStatsEntry.placeholder()
} 
