//
//  MetricsView.swift
//  PiStatsMobile
//
//  Created by Fernando Bunn on 26/07/2020.
//

import SwiftUI
import PiStatsCore

struct MetricItemViewModel {
    internal init(metrics: PiMonitorMetrics, temperatureScale: TemperatureScale = .celsius) {
        self.metrics = metrics
        self.temperatureScale = temperatureScale
    }
    
    private let metrics: PiMonitorMetrics
    private let temperatureScale: TemperatureScale

    var temperature: String {
        let temperatureValue = Measurement(value: metrics.socTemperature, unit: UnitTemperature.celsius)
        let locale = Locale.current
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.locale = locale
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter.maximumFractionDigits = 1

        let targetUnit: UnitTemperature = temperatureScale == .celsius ? .celsius : .fahrenheit
        let convertedTemperature = temperatureValue.converted(to: targetUnit)
        return measurementFormatter.string(from: convertedTemperature)
    }

    var uptime: String {
        let uptimeDuration = Duration.seconds(metrics.uptime)
        return uptimeDuration.formatted(.units(allowed: [.days, .hours, .minutes], width: .abbreviated))
    }

    var loadAverage: String {
        return metrics.loadAverage.map({"\($0)"}).joined(separator: ", ")
    }

    var memoryUsage: String {
        let usedMemory = metrics.memory.totalMemory - metrics.memory.availableMemory
        let percentageUsed = Double(usedMemory) / Double(metrics.memory.totalMemory)
        return percentageUsed.formatted(.percent.precision(.significantDigits(2)))
    }
}

fileprivate struct MetricItem: Identifiable {
    let value: String
    let systemName: String
    let helpText: String
    let id: UUID = UUID()
}

struct MetricsView: View {
    let viewModel: MetricItemViewModel
    private let imageSize: CGFloat = 15

    private func getMetricItems() -> [MetricItem] {
        return [
            MetricItem(value: viewModel.temperature,
                       systemName: SystemImages.metricTemperature,
                       helpText: "Raspberry Pi temperature"),
            MetricItem(value: viewModel.uptime,
                       systemName: SystemImages.metricUptime,
                       helpText: "Raspberry Pi uptime"),
            MetricItem(value: viewModel.loadAverage,
                       systemName: SystemImages.metricLoadAverage,
                       helpText: "Raspberry Pi load average"),
            MetricItem(value: viewModel.memoryUsage,
                       systemName: SystemImages.metricMemoryUsage,
                       helpText: "Raspberry Pi memory usage"),
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
                }, icon: {
                    Image(systemName: item.systemName)
                        .frame(width: imageSize, height: imageSize)
                })
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .font(font)
                .help(item.helpText)
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
        let memory = PiMonitorMetrics.Memory(
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
        let metrics = PiMonitorMetrics(
            socTemperature: 52.3,
            uptime: uptimeSeconds,
            loadAverage: load,
            kernelRelease: "6.6.31-v8+",
            memory: memory
        )
        return MetricItemViewModel(metrics: metrics, temperatureScale: .celsius)
    }
}
