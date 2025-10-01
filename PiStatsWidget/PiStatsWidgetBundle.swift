//
//  PiStatsWidgetBundle.swift
//  PiStatsWidget
//
//  Created by Fernando Bunn on 29/06/2025.
//

import WidgetKit
import SwiftUI

@main
struct PiStatsWidgetBundle: WidgetBundle {
    var body: some Widget {
        PiStatsOverviewWidget()
        PiMonitorWidget()
//        PiStatusControlWidget()
    }
}
