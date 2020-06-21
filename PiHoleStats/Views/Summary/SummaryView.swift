//
//  SummaryView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 10/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

private struct DisableButtonOption {
    let seconds: Int
    let text: String
    let id = UUID()
}

struct SummaryView: View {
    @EnvironmentObject var navigationController: NavigationController
    @EnvironmentObject var dataProvider: PiholeDataProvider
    @EnvironmentObject var preferences: UserPreferences
    @State private var isErrorMessagePresented = false
    @State private var isStatusAlertPresented = false
    
    private var disableButtonOptions: [DisableButtonOption] {
        [DisableButtonOption(seconds: 10, text: UIConstants.Strings.disableButtonOption10Seconds),
         DisableButtonOption(seconds: 30, text: UIConstants.Strings.disableButtonOption30Seconds),
         DisableButtonOption(seconds: 300, text: UIConstants.Strings.disableButtonOption5Minutes)]
    }
    
    var body: some View {
        VStack {
            if dataProvider.piholes.count > 0 {
                HStack {
                    Circle()
                        .fill(self.dataProvider.statusColor)
                        .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
                    Text(self.dataProvider.statusText)
                    
                    conditionalAlertMessageButton()
                    Spacer()
                    conditionalEnableDisableButtons()
                }
                Divider()
                
                summaryItems()
            } else {
                Text(UIConstants.Strings.openPreferencesToConfigureFirstPihole)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            HStack {
                Button(action: {
                    NSApplication.shared.terminate(self)
                }, label: {
                    Text(UIConstants.Strings.buttonQuit)
                })
                
                Spacer()
                
                Button(action: {
                    self.navigationController.openPreferences()
                }, label: {
                    Text(UIConstants.Strings.buttonPreferences)
                })
            }
            
        }.padding()
    }
    
    // MARK: - UI Components
    
    private func summaryItems() -> some View {
        Group {
            SummaryItem(value: self.dataProvider.totalQueries, type: .totalQuery)
            SummaryItem(value: self.dataProvider.queriesBlocked, type: .queryBlocked)
            SummaryItem(value: self.dataProvider.percentBlocked, type: .percentBlocked)
            SummaryItem(value: self.dataProvider.domainsOnBlocklist, type: .domainsOnBlocklist)
        }
    }
    
    private func conditionalEnableDisableButtons() -> some View {
        Group {
            if self.dataProvider.canDisplayEnableDisableButton {
                if preferences.displayDisableTimeOptions && self.dataProvider.status != .allDisabled {
                    enableDisableMenuButton()
                } else {
                    enableDisableButton()
                }
            }
        }
    }
    
    private func enableDisableMenuButton() -> some View {
        MenuButton(label: Text(self.dataProvider.changeStatusButtonTitle)) {
            Button(action: {
                self.dataProvider.disablePiHole()
            }, label: { Text(UIConstants.Strings.disableButtonOptionPermanently) })
            
            VStack {
                Divider()
            }
            
            ForEach(disableButtonOptions, id: \.id) { option in
                Button(action: {
                    self.dataProvider.disablePiHole(seconds: option.seconds)
                }, label: { Text(option.text) })
            }
        }.frame(maxWidth: 80)
    }
    
    private func enableDisableButton() -> some View {
        Button(action: {
            self.dataProvider.status != .allDisabled ? self.dataProvider.disablePiHole() : self.dataProvider.enablePiHole()
        }, label: {
            Text(self.dataProvider.changeStatusButtonTitle)
        })
    }
    
    private func conditionalAlertMessageButton() -> some View {
        Group {
            if self.dataProvider.hasErrorMessages {
                errorMessageButton()
            } else if self.dataProvider.status == .enabledAndDisabled {
                statusListWarningButton()
            }
        }
    }
    
    private func statusListWarningButton() -> some View {
        Button(action: {
            self.isStatusAlertPresented.toggle()
        }, label: {
            Text(UIConstants.Strings.warningButton)
        }).popover(isPresented: $isStatusAlertPresented) {
            VStack(alignment: .leading) {
                ForEach(self.dataProvider.piholes) {pihole in
                    HStack {
                        Circle()
                            .fill(pihole.active ? UIConstants.Colors.enabled : UIConstants.Colors.disabled)
                            .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
                        Text(pihole.address)
                    }
                }
            }.padding()
        }
    }
    
    private func errorMessageButton() -> some View {
        Button(action: {
            self.isErrorMessagePresented.toggle()
        }, label: {
            Text(UIConstants.Strings.warningButton)
        }).popover(isPresented: $isErrorMessagePresented) {
            VStack {
                ForEach(self.dataProvider.piholes) {pihole in
                    if pihole.pollingError != nil {
                        Text("\(pihole.address): \(pihole.pollingError!)")
                    }
                    if pihole.actionError != nil {
                        Text("\(pihole.address): \(pihole.actionError!)")
                    }
                }
                HStack {
                    Button(action: {
                        self.dataProvider.resetErrorMessage()
                        self.isErrorMessagePresented.toggle()
                    }, label: {
                        Text(UIConstants.Strings.buttonClearErrorMessages)
                    })
                }
            }.padding()
        }
    }
    
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}
