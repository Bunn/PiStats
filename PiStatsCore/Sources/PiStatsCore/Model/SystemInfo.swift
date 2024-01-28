//
//  File.swift
//  
//
//  Created by Fernando Bunn on 1/28/24.
//

import Foundation

public struct SystemInfo: Codable {
    let system: System
    let took: Double

    struct System: Codable {
        let uptime: Int
        let memory: Memory
        let procs: Int
        let cpu: CPU

        struct Memory: Codable {
            let ram: RAM
            let swap: Swap

            struct RAM: Codable {
                let total: Int
                let free: Int
                let used: Int
                let available: Int
                let percentUsed: Double

                enum CodingKeys: String, CodingKey {
                    case total
                    case free
                    case used
                    case available
                    case percentUsed = "%used"
                }
            }

            struct Swap: Codable {
                let total: Int
                let free: Int
                let used: Int
                let percentUsed: Double

                enum CodingKeys: String, CodingKey {
                    case total
                    case free
                    case used
                    case percentUsed = "%used"
                }
            }
        }

        struct CPU: Codable {
            let nprocs: Int
            let load: Load

            struct Load: Codable {
                let raw: [Double]
                let percent: [Double]
            }
        }
    }
}
