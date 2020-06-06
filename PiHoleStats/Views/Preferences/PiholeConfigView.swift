//
//  ContentView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PiholeConfigView: View {
    @EnvironmentObject var piHoleController: PiholeController
    @State private var selectedItem: Pihole?
    @State var items = [Pihole]()
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                List(selection: $selectedItem) {
                    ForEach(piHoleController.piholes) { pihole in
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
                    if piHoleController.piholes.count > 0 {
                        Text("Select a pi-hole on the left or click Add to setup a new pi-hole.")
                            .multilineTextAlignment(.center)
                    } else {
                        Text("No pi-holes available, click Add to setup a new pi-hole")
                            .multilineTextAlignment(.center)
                    }
                }.padding()
                Spacer()
            }
        }.onAppear {
            self.selectedItem = self.piHoleController.piholes.first
        }
    }
    
    private func addStubPihole() {
        let pihole = piHoleController.addStubPihole()
        items.append(pihole)
        selectedItem = pihole
    }
    
    private func removeSelectedPihole() {
        if let pihole = self.selectedItem {
            remove(pihole)
        }
        selectedItem = nil
    }
    
    private func remove(_ pihole: Pihole) {
        piHoleController.remove(pihole)
    }
}

struct PiHoleConfigView_Previews: PreviewProvider {
    static var previews: some View {
        PiholeConfigView()
    }
}
