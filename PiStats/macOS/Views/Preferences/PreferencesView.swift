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
                                
                                PiholePreferenceListRow(pihole: pihole)
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
                    OptionsButtonView()
                    Spacer()
                    Divider()
                }.background(Color("backgroundColor"))
                    .frame(height: 40)
                
                AddRemoveFooterView()
                
                
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
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView(viewModel: PreferencesViewModel.init(piholeManager: PiholeManager.preview()))
    }
}
