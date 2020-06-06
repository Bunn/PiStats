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
    @State var items = [String]()

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
                    Text("Select an item")
                    Spacer()

                }
            }.onAppear {
                self.selectedItem = self.piHoleController.piholes.first
        }
    }
    
    private func addStubPihole() {
        let pihole = piHoleController.addStubPihole()
        items.append(pihole.id.uuidString)
    }
    
    private func removeSelectedPihole() {
        if let pihole = self.selectedItem {
            remove(pihole)
        }
        self.selectedItem = nil
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
