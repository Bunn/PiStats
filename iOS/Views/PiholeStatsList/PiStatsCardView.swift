//
//  PiStatsCardView.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//
import SwiftUI

struct PiStatsCardView: View {
    @ObservedObject var data: PiholeSummaryData
    let updater: PiholeSummaryDataUpdater
    @ObservedObject var settingsStore: SettingsStore
    @State private var showingDisableActionSheet = false

    var body: some View {
        VStack {
            HStack {
                StatusHeaderView(data: data)
                Spacer()
            }

            if data.hasError, let error = data.currentError {
                ErrorMessageView(error: error)
                    .padding(.top, 8)
            }

            if settingsStore.displayStatsAsList {
                ListView(data: data)
                    .padding(.vertical)
            } else {
                CardViewGrid(data: data)
                    .padding(.vertical)
            }

            if let metrics = data.monitorMetrics {
                Divider()
                MetricsView(viewModel: .init(metrics: metrics, temperatureScale: settingsStore.temperatureScale))
                    .contentTransition(.numericText())
            }
            toggleButton()
        }
        .padding()
        .glassEffect(in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
        .actionSheet(isPresented: $showingDisableActionSheet) {
            ActionSheet(
                title: Text(UserText.disablePiholeOptionsTitle),
                buttons: createDisableActionButtons()
            )
        }
    }
}

#Preview {
    PiStatsCardView(data: .mockData, updater: .init(pihole: .init(name: "Test", address: "1234", version: .v5)), settingsStore: SettingsStore())
        .padding()
}

extension PiStatsCardView {
    private func toggleButton() -> some View {
        if data.status == .disabled {
            return AnyView(enableButton())
        } else if data.status == .enabled {
            return AnyView(disableButton())
        } else {
            return AnyView(EmptyView())
        }
    }

    private func disableButton() -> some View {
        Button {
            if settingsStore.disablePermanently {
                Task {
                    await updater.disable()
                }
            } else {
                showingDisableActionSheet = true
            }
        } label: {
            HStack(spacing: 0) {
                Label(UserText.disableButton, systemImage: SystemImages.disablePiholeButton)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .glassEffect(.regular.tint(AppColors.statusOffline).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))

        }
    }

    private func enableButton() -> some View {
        Button {
            Task {
                await updater.enable()
            }
        } label: {
            HStack(spacing: 0) {
                Label(UserText.enableButton, systemImage: SystemImages.enablePiholeButton)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .glassEffect(.regular.tint(AppColors.totalQueries).interactive(), in: .rect(cornerRadius: LayoutConstants.defaultCornerRadius))
        }
    }

    private func createDisableActionButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        for disableTime in settingsStore.customDisableTimes {
            buttons.append(.default(Text(disableTime.displayName)) {
                Task {
                    await updater.disable(timer: disableTime.seconds)
                }
            })
        }
        
        buttons.append(.destructive(Text(UserText.disablePiholeOptionsPermanently)) {
            Task {
                await updater.disable()
            }
        })
        
        buttons.append(.cancel())
        
        return buttons
    }
}
