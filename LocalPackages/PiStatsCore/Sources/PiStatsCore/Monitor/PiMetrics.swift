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
        
        public init(totalMemory: Int, freeMemory: Int, availableMemory: Int) {
            self.totalMemory = totalMemory
            self.freeMemory = freeMemory
            self.availableMemory = availableMemory
        }
    }

    public let socTemperature: Double
    public let uptime: Double
    public let loadAverage: [Double]
    public let kernelRelease: String
    public let memory: Memory
    
    public init(socTemperature: Double, uptime: Double, loadAverage: [Double], kernelRelease: String, memory: Memory) {
        self.socTemperature = socTemperature
        self.uptime = uptime
        self.loadAverage = loadAverage
        self.kernelRelease = kernelRelease
        self.memory = memory
    }
}


