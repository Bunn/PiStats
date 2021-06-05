//
//  MonitorItemType.swift
//  PiStats
//
//  Created by Fernando Bunn on 05/06/2021.
//

import Foundation
import SwiftUI

enum MonitorItemType {
    case temperature
    case uptime
    case loadAverage
    case memoryPercentUsage
    
    var icon: Image {
        switch self {
        case .temperature:
            return Image(systemName: "thermometer")
        case .uptime:
            return Image(systemName: "power")
        case .loadAverage:
            return Image(systemName: "cpu")
        case .memoryPercentUsage:
            return Image(systemName: "memorychip")
        }
    }
}
