//
//  SettingsView.swift
//  PiStats
//
//  Created by Fernando Bunn on 22/02/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        List {
            Section(header: Text(UserText.Settings.Sections.interface)) {
                Toggle(isOn: $viewModel.displayStatsAsList) {
                    Label(UserText.Settings.displayAsListToggle, systemImage: SystemImages.settingsDisplayAsList)
                }
                
                Toggle(isOn: $viewModel.displayAllPiholes) {
                    Label(UserText.Settings.displayAllPiholesToggle, systemImage: SystemImages.settingsDisplayAllPiholesInSingleCard)
                }
            }
            
            Section(header: Text(UserText.Settings.Sections.enableDisable)) {
                Toggle(isOn: $viewModel.disablePermanently.animation()) {
                    Label(UserText.Settings.alwaysDisablePermanentlyToggle, systemImage: SystemImages.settingsDisablePermanently)
                }
                
                if viewModel.disablePermanently == false {
                    NavigationLink(destination: CustomDisableTimesView(viewModel: viewModel)) {
                        Label(UserText.Settings.customizeDisableTimes, systemImage: SystemImages.customizeDisableTimes)
                    }
                }
            }
            
            Section(header: Text(UserText.Settings.Sections.piMonitor)) {
                Label(UserText.Settings.temperatureScaleLabel, systemImage: SystemImages.piMonitorTemperature)
                
                Picker(selection: $viewModel.temperatureScale, label: Text("")) {
                    ForEach(TemperatureScale.allCases, id: \.self) { scale in
                        Text(scale.displayName).tag(scale)
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }
            
            Section(header: Text(UserText.Settings.Sections.about), footer: Text("\(UserText.Settings.versionLabel) \(appVersion)")) {
                Button(action: {
                    openGithubPage()
                }, label: {
                    Label(UserText.Settings.sourceCodeLink, systemImage: SystemImages.piStatsSourceCode)
                        .foregroundColor(.primary)
                })
                
                Button(action: {
                    openPiStatsMacOS()
                }, label: {
                    Label(UserText.Settings.macOSLink, systemImage: SystemImages.piStatsMacOS)
                        .foregroundColor(.primary)
                })

                Button(action: {
                    leaveAppReview()
                }, label: {
                    Label(UserText.Settings.leaveReview, systemImage: SystemImages.leaveReview)
                        .foregroundColor(.primary)
                })
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle(UserText.settingsNavigationTitle)
    }
    
    private func leaveAppReview() {
        UIApplication.shared.open(PiStatsURL.review, options: [:], completionHandler: nil)
    }
    
    private func openGithubPage() {
        UIApplication.shared.open(PiStatsURL.piStatsMobileGitHub)
    }
    
    private func openPiStatsMacOS() {
        UIApplication.shared.open(PiStatsURL.piStatsMacOSGitHub)
    }
}

fileprivate struct PiStatsURL {
    static let review = URL(string: "https://apps.apple.com/us/app/pi-stats-mobile/id1523024268?action=write-review&mt=8")!
    static let piStatsMobileGitHub = URL(string: "https://github.com/Bunn/PiStatsMobile")!
    static let piStatsMacOSGitHub = URL(string: "https://github.com/Bunn/PiStats")!
}

#Preview {
    let viewModel = SettingsViewModel(userDefaults: UserDefaults.shared())

    return SettingsView(viewModel: viewModel)

}
