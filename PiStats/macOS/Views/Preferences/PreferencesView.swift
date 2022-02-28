//
//  PreferencesView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import SwiftUI
import PiStatsCore

struct PreferencesView: View {
    @ObservedObject var viewModel: PreferencesViewModel
    @State private var selectedPihole: Pihole?

    var body: some View {
        HStack {
            VStack(spacing:0) {
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.piholes) { pihole in
                            
                            ZStack (alignment: .leading) {
                                if selectedPihole == pihole {
                                    Color.accentColor
                                } else {
                                    Color("backgroundColor")
                                }
                                
                                piholeRow(pihole)
                                    .onTapGesture {
                                        selectedPihole = pihole
                                    }
                            }
                            
                        }
                    }
                }
                .background(Color("backgroundColor"))
                .border(Color("border"))
                
                //PiStats Options
                VStack(spacing:0) {
                    Spacer()
                    settingsRow
                    Spacer()
                    Divider()
                }.background(Color("backgroundColor"))
                    .frame(height: 40)
                
                addRemovePiholeFooter
                
                
            }.border(Color("border"))
                .frame(width: 200)
            if let selectedPihole = selectedPihole {
                PiholeConfigurationView(piholeViewModel: Binding.constant(PiholeConfigurationViewModel(pihole: selectedPihole)))
            } else {
                Text("Please select or add a pi-hole")
                    .frame(width: 410)
            }
            
        }
        .frame(maxWidth: 600, minHeight: 450, idealHeight: 450)
        .padding(30)
        .onAppear {
            autoSelectPihole()
        }
    }
    
    private func autoSelectPihole() {
        selectedPihole = viewModel.piholes.first
    }
    
    func piholeRow(_ pihole: Pihole) -> some View {
        HStack {
            HStack {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                    
                        .frame(width: 35, height: 35)
                        .shadow(radius: 1)
                        .padding(8)
                    
                    Image(systemName: "shield")
                        .renderingMode(.original)
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                }
                
                VStack (alignment: .leading) {
                    Text(pihole.address)
                        .font(.title3)
                    Text(pihole.enabled ? "Enabled" : "Disabled")
                        .font(.caption)
                }
            }
            
            
            Spacer()
            
        }.contentShape(Rectangle())
    }
    
    
    var settingsRow: some View {
        HStack {
            Button {
                print("settings")
            } label: {
                HStack {
                    Image(systemName: "gear")
                        .padding(.leading)
                    Text("Pi Stats Options")
                }
            } .buttonStyle(.plain)
            
            
            Spacer()
        }
    }
    
    
    var addRemovePiholeFooter: some View {
        let buttonWidth: CGFloat = 25
        let buttonHeight: CGFloat = 20
        let footerHeight: CGFloat = 20
        
        return HStack(spacing:0) {
            Button {
                print("+")
            } label: {
                Image(systemName: "plus")
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
                
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button {
                print("-")
                viewModel.test()
            } label: {
                Image(systemName: "minus")
                    .frame(width: buttonWidth, height: buttonHeight)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            
            Divider()
            Spacer()
        }.frame(height:footerHeight)
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: PreferencesViewModel.init(piholeManager: PiholeManager.preview()))
    }
}
