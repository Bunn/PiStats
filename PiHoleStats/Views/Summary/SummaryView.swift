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
    
    private var disableButtonOptions: [DisableButtonOption] {
        [DisableButtonOption(seconds: 10, text: UIConstants.Strings.disableButtonOption10Seconds),
         DisableButtonOption(seconds: 30, text: UIConstants.Strings.disableButtonOption30Seconds),
         DisableButtonOption(seconds: 300, text: UIConstants.Strings.disableButtonOption5Minutes)]
    }
    
    var body: some View {
        VStack {
            if dataProvider.errorMessage.isEmpty {
                HStack {
                    Circle()
                        .fill(self.dataProvider.statusColor)
                        .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
                    Text(self.dataProvider.statusText)
                    
                    Spacer()
                    
                    if self.dataProvider.canDisplayEnableDisableButton {
                        if preferences.displayDisableTimeOptions && self.dataProvider.status != .allDisabled {
                            
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
                            
                        } else {
                            Button(action: {
                                self.dataProvider.status != .allDisabled ? self.dataProvider.disablePiHole() : self.dataProvider.enablePiHole()
                            }, label: {
                                Text(self.dataProvider.changeStatusButtonTitle)
                            })
                        }
                    }
                }
                
                Divider()
                
                SummaryItem(value: self.dataProvider.totalQueries, type: .totalQuery)
                SummaryItem(value: self.dataProvider.queriesBlocked, type: .queryBlocked)
                SummaryItem(value: self.dataProvider.percentBlocked, type: .percentBlocked)
                SummaryItem(value: self.dataProvider.domainsOnBlocklist, type: .domainsOnBlocklist)
                
            } else {
                Text(dataProvider.errorMessage)
                    .multilineTextAlignment(.center)
                if !preferences.host.isEmpty {
                    Button(action: {
                        self.dataProvider.resetErrorMessage()
                    }, label: {
                        Text(UIConstants.Strings.buttonOK)
                    })
                }
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
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView()
    }
}
