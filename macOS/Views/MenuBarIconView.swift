//
//  MenuBarIconView.swift
//  macOS
//
//  Created by Fernando Bunn on 28/01/2025.
//

import SwiftUI
import PiStatsCore

struct MenuBarIconView: View {
    @ObservedObject var dataManager: PiholeDataManager
    
    var body: some View {
        Image(systemName: dataManager.menuBarIcon)
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(iconColor)
            .help(statusTooltip)
    }
    
    private var iconColor: Color {
        switch dataManager.overallStatus {
        case .enabled:
            return .green
        case .disabled:
            return .red
        case .unknown:
            return .orange
        }
    }
    
    private var statusTooltip: String {
        guard let listUpdater = dataManager.listUpdater, !listUpdater.dataUpdaters.isEmpty else {
            return UserText.MenuBar.noPiholesConfigured
        }
        
        let piholeCount = listUpdater.dataUpdaters.count
        let enabledCount = listUpdater.dataUpdaters.filter { $0.summary.status == .enabled }.count
        let disabledCount = listUpdater.dataUpdaters.filter { $0.summary.status == .disabled }.count
        let errorCount = listUpdater.dataUpdaters.filter { $0.summary.hasError }.count
        
        if errorCount > 0 {
            return String(format: UserText.MenuBar.withErrors, errorCount, piholeCount)
        }
        
        switch dataManager.overallStatus {
        case .enabled:
            return String(format: UserText.MenuBar.allEnabled, piholeCount)
        case .disabled:
            return String(format: UserText.MenuBar.allDisabled, piholeCount)
        case .unknown:
            return String(format: UserText.MenuBar.mixedStatus, enabledCount, disabledCount)
        }
    }
}

#Preview {
    MenuBarIconView(dataManager: PiholeDataManager())
}
