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
    
    private var disableButtonOptions: [DisableButtonOption] {
        [DisableButtonOption(seconds: 10, text: UIConstants.Strings.disableButtonOption10Seconds),
         DisableButtonOption(seconds: 30, text: UIConstants.Strings.disableButtonOption30Seconds),
         DisableButtonOption(seconds: 300, text: UIConstants.Strings.disableButtonOption5Minutes)]
    }
    
    var body: some View {
        VStack {
            HStack {
                Circle()
                    .fill(self.dataProvider.statusColor)
                    .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
                Text(self.dataProvider.statusText)
                
                if self.dataProvider.hasErrorMessages {
                    Button(action: {
                        self.isErrorMessagePresented.toggle()
                    }, label: {
                        Text("⚠️")
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
