//
//  PopoverView.swift
//  PiStats-macOS
//
//  Created by Fernando Bunn on 5/27/24.
//

import SwiftUI
import PiStatsCore

struct PopoverView: View {
    @ObservedObject var dataManager: PiholeDataManager
    @ObservedObject var prefs: MacPreferences
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack {
            if let listUpdater = dataManager.listUpdater, !listUpdater.dataUpdaters.isEmpty {
                if listUpdater.dataUpdaters.count > 1 {
                    PiholesOverviewCard(listUpdater: listUpdater, prefs: prefs)
                }
                
                ForEach(listUpdater.dataUpdaters.sortedByNameThenHost()) { dataUpdater in
                    PiStatPopoverView(dataUpdater: dataUpdater, temperatureScale: prefs.temperatureScale, prefs: prefs)
                }
            } else {
                emptyStateView
            }

            footerButtons
        }
        .padding()
    }

    private var footerButtons: some View {
        HStack {
            VStack (alignment: .leading) {
                Button(action: {
                    openMainWindow()
                }) {
                    HStack {
                        Image(systemName: SystemImages.manage)
                            .font(.title)
                            .bold()
                        Text(UserText.Popover.manageButton)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())

                Button(action: {
                    quitApplication()
                }) {
                    HStack {
                        Image(systemName: SystemImages.quit)
                            .font(.title)
                            .bold()
                        Text(UserText.Popover.quitButton)
                    }
                }
                .buttonStyle(BorderlessButtonStyle())
            }

            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: SystemImages.shieldSlash)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(UserText.Popover.noPiholesTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(UserText.Popover.noPiholesInstructions)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        
        for window in NSApp.windows where window.title == UserText.MenuBar.appName && window.isVisible {
            window.makeKeyAndOrderFront(nil)
            return
        }
        
        openWindow(id: AppIdentifiers.mainWindowSceneId)
    }
    
    private func quitApplication() {
        NSApp.terminate(nil)
    }
}

struct PiStatPopoverView: View {
    @ObservedObject var dataUpdater: PiholeSummaryDataUpdater
    let temperatureScale: TemperatureScale
    @ObservedObject var prefs: MacPreferences

    var body: some View {
        VStack {
            HStack {
                StatusHeaderView(data: dataUpdater.summary)
                Spacer()
                ActionButtonView(
                    status: dataUpdater.summary.status,
                    prefs: prefs,
                    onEnable: { await dataUpdater.enable() },
                    onDisable: { timer in await dataUpdater.disable(timer: timer) }
                )
            }

            if dataUpdater.summary.hasError, let error = dataUpdater.summary.currentError {
                ErrorMessageView(error: error, isCollapsible: false)
            }

            Divider()

            HStack {
                Text(UserText.Popover.dataSection)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ListView(data: dataUpdater.summary)

            if let metrics = dataUpdater.summary.monitorMetrics {
                Divider()
                HStack {
                    Text(UserText.Popover.deviceSection)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                
                MetricsView(viewModel: .init(metrics: metrics, temperatureScale: temperatureScale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(backgroundOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    private var backgroundOpacity: CGFloat {
        if #available(macOS 26.0, *) {
            return 0.5
        } else {
            return 1
        }
    }
}

struct PiholesOverviewCard: View {
    @ObservedObject var listUpdater: PiholeListUpdater
    @ObservedObject var prefs: MacPreferences
    
    private var hasAtLeastOneKnownStatus: Bool {
        listUpdater.dataUpdaters.contains { updater in
            updater.summary.status == .enabled || updater.summary.status == .disabled
        }
    }
    
    private var overallStatus: PiholeStatus {
        let knownStatuses = listUpdater.dataUpdaters
            .map { $0.summary.status }
            .filter { $0 == .enabled || $0 == .disabled }
        
        if knownStatuses.isEmpty {
            return .unknown
        }
        
        let uniqueStatuses = Set(knownStatuses)
        if uniqueStatuses.count == 1, let singleStatus = uniqueStatuses.first {
            return singleStatus
        }
        
        return .disabled
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(UserText.Popover.allPiholesTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if hasAtLeastOneKnownStatus {
                    ActionButtonView(
                        status: overallStatus,
                        prefs: prefs,
                        onEnable: { await enableAllPiholes() },
                        onDisable: { timer in await disableAllPiholes(timer: timer) }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }
    
    private func enableAllPiholes() async {
        await withTaskGroup(of: Void.self) { group in
            for dataUpdater in listUpdater.dataUpdaters {
                group.addTask {
                    await dataUpdater.enable()
                }
            }
        }
    }
    
    private func disableAllPiholes(timer: Int?) async {
        await withTaskGroup(of: Void.self) { group in
            for dataUpdater in listUpdater.dataUpdaters {
                group.addTask {
                    await dataUpdater.disable(timer: timer)
                }
            }
        }
    }
}

#Preview {
    PopoverView(dataManager: PiholeDataManager(), prefs: MacPreferences())
        .frame(width: 400)
}
