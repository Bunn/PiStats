//
//  PiMetrics.swift
//  
//
//  Created by Fernando Bunn on 25/07/2020.
//

import Foundation

public struct PiMonitorMetrics: Codable, Sendable {
    public struct Memory: Codable, Sendable {
        public let totalMemory: Int
        public let freeMemory: Int
        public let availableMemory: Int
        /// Used RAM reported by the Pi-hole API, when available.
        public let usedMemory: Int?
        /// Used RAM percentage on a 0...100 scale, when reported by the API.
        public let percentageUsed: Double?
        
        public init(totalMemory: Int,
                    freeMemory: Int,
                    availableMemory: Int,
                    usedMemory: Int? = nil,
                    percentageUsed: Double? = nil) {
            self.totalMemory = totalMemory
            self.freeMemory = freeMemory
            self.availableMemory = availableMemory
            self.usedMemory = usedMemory
            self.percentageUsed = percentageUsed
        }

        /// Fraction of RAM in use on a 0...1 scale. Pi-hole's reported
        /// percentage is preferred; legacy Pi Monitor values fall back to
        /// total minus available memory, matching Linux's `free` calculation.
        public var usedFraction: Double? {
            guard totalMemory > 0 else { return nil }

            let fraction: Double
            if let percentageUsed, percentageUsed.isFinite {
                fraction = percentageUsed / 100
            } else {
                let used = usedMemory ?? (totalMemory - availableMemory)
                fraction = Double(used) / Double(totalMemory)
            }

            return min(max(fraction, 0), 1)
        }
    }

    /// CPU/SoC temperature normalized to Celsius, when a sensor is available.
    public let socTemperature: Double?
    public let uptime: Double
    public let loadAverage: [Double]
    public let kernelRelease: String
    public let memory: Memory
    
    public init(socTemperature: Double?, uptime: Double, loadAverage: [Double], kernelRelease: String, memory: Memory) {
        self.socTemperature = socTemperature
        self.uptime = uptime
        self.loadAverage = loadAverage
        self.kernelRelease = kernelRelease
        self.memory = memory
    }
}
