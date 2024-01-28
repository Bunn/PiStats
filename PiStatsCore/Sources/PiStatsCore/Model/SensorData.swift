//  SensorData.swift
//
//  Created by Fernando Bunn
//  Copyright © 2024 Fernando Bunn. All rights reserved.
//

import Foundation

public struct SensorData: Codable {
    let sensors: Sensors
    let took: Double

    struct Sensors: Codable {
        let list: [Sensor]
        let cpuTemp: Double
        let hotLimit: Int
        let unit: String

        enum CodingKeys: String, CodingKey {
            case list
            case cpuTemp = "cpu_temp"
            case hotLimit = "hot_limit"
            case unit
        }

        struct Sensor: Codable {
            let name: String
            let path: String
            let source: String
            let temps: [Temperature]

            struct Temperature: Codable {
                let name: String?
                let value: Double
                let max: Double?
                let crit: Int
                let sensor: String
            }
        }
    }
}
