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
    @EnvironmentObject var viewModel: PiHoleViewModel
    @EnvironmentObject var preferences: Preferences
    
    private var disableButtonOptions: [DisableButtonOption] {
        [DisableButtonOption(seconds: 10, text: UIConstants.Strings.disableButtonOption10Seconds),
         DisableButtonOption(seconds: 30, text: UIConstants.Strings.disableButtonOption30Seconds),
         DisableButtonOption(seconds: 300, text: UIConstants.Strings.disableButtonOption5Minutes)]
    }
    
    var body: some View {
        VStack {
            if viewModel.errorMessage.isEmpty {
                HStack {
                    Circle()
                        .fill(self.viewModel.active ? UIConstants.Colors.active : UIConstants.Colors.offline)
                        .frame(width: UIConstants.Geometry.circleSize, height: UIConstants.Geometry.circleSize)
                    Text(self.viewModel.status)
                    
                    Spacer()
                    
                    if !preferences.apiToken.isEmpty {
                        if preferences.displayDisableTimeOptions && self.viewModel.active {
                           
                            MenuButton(label: Text(self.viewModel.changeStatusButtonTitle)) {
                                Button(action: {
                                    self.viewModel.disablePiHole()
                                }, label: { Text(UIConstants.Strings.disableButtonOptionPermanently) })
                                
                                VStack {
                                    Divider()
                                }
                                
                                ForEach(disableButtonOptions, id: \.id) { option in
                                    Button(action: {
                                        self.viewModel.disablePiHole(seconds: option.seconds)
                                    }, label: { Text(option.text) })
                                }
                            }.frame(maxWidth: 80)
                            
                        } else {
                            Button(action: {
                                self.viewModel.active ? self.viewModel.disablePiHole() : self.viewModel.enablePiHole()
                            }, label: {
                                Text(self.viewModel.changeStatusButtonTitle)
                            })
                        }
                    }
                }
                
                Divider()
                
                SummaryItem(value: self.viewModel.totalQueries, type: .totalQuery)
                SummaryItem(value: self.viewModel.queriesBlocked, type: .queryBlocked)
                SummaryItem(value: self.viewModel.percentBlocked, type: .percentBlocked)
                SummaryItem(value: self.viewModel.domainsOnBlocklist, type: .domainsOnBlocklist)
                
            } else {
                Text(viewModel.errorMessage)
                    .multilineTextAlignment(.center)
                if !viewModel.isSettingsEmpty {
                    Button(action: {
                        self.viewModel.resetErrorMessage()
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
