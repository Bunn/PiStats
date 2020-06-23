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
    @EnvironmentObject var piholeDataProvider: PiholeDataProvider

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedItem) {
                    ForEach(piholeDataProvider.piholes) { pihole in
                        Text(pihole.address).tag(pihole)
                    }
                }
                HStack(spacing: 0) {
                    Button(action: {
                        self.addStubPihole()
                    }, label: {
                        Text("Add")
                    })
                    
                    Button(action: {
                        self.removeSelectedPihole()
                    }, label: {
                        Text("Remove")
                    }).disabled(selectedItem == nil)
                }
            }
            if selectedItem != nil {
                PiholeItemConfigView(piholeViewModel: PiholeViewModel(piHole: selectedItem!))
            } else {
                Spacer()
                VStack {
                    if piholeDataProvider.piholes.count > 0 {
                        Text("Select a pi-hole on the left or click Add to setup a new pi-hole.")
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No pi-holes available, click Add to setup a new pi-hole")
                            .multilineTextAlignment(.center)
                    }
                }.padding()
                Spacer()
            }
        }
        .frame(width: 480, height: 250)
        .padding()
        .onAppear {
            self.selectedItem = self.piholeDataProvider.piholes.first
        }
    }
    
    private func addStubPihole() {
        let pihole = piholeDataProvider.addStubPihole()
        selectedItem = pihole
    }
    
    private func removeSelectedPihole() {
        if let pihole = self.selectedItem {
            remove(pihole)
        }
        selectedItem = nil
    }
    
    private func remove(_ pihole: Pihole) {
        piholeDataProvider.remove(pihole)
    }
}
