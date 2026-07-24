//
//  MetricsView.swift
//  PiStatsMobile
//
//  Created by Fernando Bunn on 26/07/2020.
//

import SwiftUI
import PiStatsCore

private let metricMeasurementFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.locale = Locale.current
    formatter.unitOptions = .providedUnit
    formatter.numberFormatter.maximumFractionDigits = 1
    return formatter
}()

struct MetricItemViewModel {
    internal init(metrics: PiholeSystemMetrics, temperatureScale: TemperatureScale = .celsius) {
        self.metrics = metrics
        self.temperatureScale = temperatureScale
    }
    
    private let metrics: PiholeSystemMetrics
    private let temperatureScale: TemperatureScale

    var temperature: String {
        guard let socTemperature = metrics.socTemperature else { return "N/A" }
        let temperatureValue = Measurement(value: socTemperature, unit: UnitTemperature.celsius)
        let targetUnit: UnitTemperature = temperatureScale == .celsius ? .celsius : .fahrenheit
        let convertedTemperature = temperatureValue.converted(to: targetUnit)
        return metricMeasurementFormatter.string(from: convertedTemperature)
    }

    var uptime: String {
        let uptimeDuration = Duration.seconds(metrics.uptime)
        return uptimeDuration.formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated))
    }

    var loadAverage: String {
        guard !metrics.loadAverage.isEmpty else { return "N/A" }
        return metrics.loadAverage
            .prefix(3)
            .map { $0.formatted(.number.precision(.fractionLength(2))) }
            .joined(separator: " · ")
    }

    var memoryUsage: String {
        guard let usedFraction = metrics.memory.usedFraction else { return "N/A" }
        let percentage = usedFraction.formatted(.percent.precision(.fractionLength(0)))
        return String(localized: "\(percentage) used")
    }
}

fileprivate struct MetricItem: Identifiable {
    let value: String
    let systemName: String
    let helpText: String
    var id: String { systemName }
}

struct MetricsView: View {
    let viewModel: MetricItemViewModel
    private let imageSize: CGFloat = 15

    private func getMetricItems() -> [MetricItem] {
        return [
            MetricItem(value: viewModel.temperature,
                       systemName: SystemImages.metricTemperature,
                       helpText: "CPU temperature"),
            MetricItem(value: viewModel.uptime,
                       systemName: SystemImages.metricUptime,
                       helpText: "System uptime"),
            MetricItem(value: viewModel.loadAverage,
                       systemName: SystemImages.metricLoadAverage,
                       helpText: "System load average over 1, 5, and 15 minutes"),
            MetricItem(value: viewModel.memoryUsage,
                       systemName: SystemImages.metricMemoryUsage,
                       helpText: "Memory used"),
        ]
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 10) {
            ForEach(getMetricItems()) { item in
                Label(title: {
                    Text(item.value)
                        .monospacedDigit()
                }, icon: {
                    Image(systemName: item.systemName)
                        .frame(width: imageSize, height: imageSize)
                })
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(font)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(item.helpText)
                .accessibilityValue(item.value)
            }
        }
    }

    private var font: Font {
#if os(iOS)
        return .footnote
#else
        return .body
#endif
    }
}

#Preview {
    MetricsView(viewModel: .mock)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
}

extension MetricItemViewModel {
    static var mock: MetricItemViewModel {
        // Memory values in bytes (Int)
        let total: Int = 1_073_741_824 // 1 GB
        let free: Int = 536_870_912    // 512 MB

        // Ensure parameter order matches the model: freeMemory before availableMemory
        let memory = PiholeSystemMetrics.Memory(
            totalMemory: total,
            freeMemory: free,
            availableMemory: free
        )

        // Uptime as Double if required by the model
        let oneDay: Double = 60 * 60 * 24
        let threeDays: Double = oneDay * 3
        let fortyFiveMinutes: Double = 60 * 45
        let uptimeSeconds: Double = threeDays + fortyFiveMinutes

        let load: [Double] = [0.23, 0.35, 0.40]

        // Provide kernelRelease before memory to match the initializer order
        let metrics = PiholeSystemMetrics(
            socTemperature: 52.3,
            uptime: uptimeSeconds,
            loadAverage: load,
            kernelRelease: "6.6.31-v8+",
            memory: memory
        )
        return MetricItemViewModel(metrics: metrics, temperatureScale: .celsius)
    }
}
