//
//  ContentView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PiholeListConfigView: View {
    @State private var selectedItem: Pihole?
    @ObservedObject var piholeListViewModel: PiholeListViewModel

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedItem) {
                    ForEach(piholeListViewModel.piholes) { pihole in
                        Text(pihole.address).tag(pihole)
                    }
                }
                    
                AddRemoveButton(removeEnabled: selectedItem != nil) { isAdd in
                    if isAdd {
                        addStubPihole()
                    } else {
                        removeSelectedPihole()
                    }
                }
                .padding(.top, 8)
            }
            if selectedItem != nil {
                PiholeItemConfigView(piholeViewModel: piholeListViewModel.itemViewModel(selectedItem!))
            } else {
                Spacer()
                VStack {
                    if piholeListViewModel.piholes.count > 0 {
                        Text(UIConstants.Strings.noSelectedPiholeMessage)
                            .multilineTextAlignment(.center)
                    } else {
                        Text(UIConstants.Strings.noAvailablePiholeToSelectMessage)
                            .multilineTextAlignment(.center)
                    }
                }.padding()
                Spacer()
            }
        }
        .frame(width: 480, height: 250)
        .padding()
        .onAppear {
            self.selectedItem = self.piholeListViewModel.piholes.first
        }
    }
    
    private func addStubPihole() {
        let pihole = piholeListViewModel.addStubPihole()
        selectedItem = pihole
    }
    
    private func removeSelectedPihole() {
        if let pihole = self.selectedItem {
            remove(pihole)
        }
        selectedItem = nil
    }
    
    private func remove(_ pihole: Pihole) {
        piholeListViewModel.remove(pihole)
    }
}
