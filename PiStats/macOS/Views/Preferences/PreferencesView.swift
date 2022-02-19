//
//  PreferencesView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import SwiftUI
import PiStatsCore

struct PreferencesView: View {
    @StateObject var viewModel: PreferencesViewModel
    @State var selectedPihole: Pihole?
    
    var body: some View {
        HStack {
            VStack(spacing:0) {
                List(viewModel.piholes, selection: $selectedPihole) { pihole in
                    piholeRow(pihole)
                    Divider()
                }.border(.gray)
      
                VStack(spacing:0) {
                    Spacer()
                    settingsRow
                    Spacer()
                    Divider()
                }.background(Color.white)
                    .frame(height: 40)
                
                addRemoveFooter
                
            }.border(.gray)
                .frame(width: 200)
            
            PiholeConfigurationView()
        }
        .frame(maxWidth: 600, minHeight: 450, idealHeight: 450)
        .padding()
    }
    
    func piholeRow(_ pihole: Pihole) -> some View {
        HStack {
            HStack {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                        
                        .frame(width: 35, height: 35)
                        .shadow(radius: 1)

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
            
        }
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
    
    
    var addRemoveFooter: some View {
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
