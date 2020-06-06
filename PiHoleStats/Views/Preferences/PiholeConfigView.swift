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
                        ForEach(piHoleController.piHoles) { pihole in
                            Text(pihole.address).tag(pihole)
                        }
                    }
                    
                    HStack(spacing: 0) {
                        Button(action: {
                            let pihole = self.piHoleController.addStubPihole()
                            self.items.append(pihole.id.uuidString)
                        }, label: {
                            Text("Add")
                        })
                        
                        Button(action: {
                            if let item = self.selectedItem {
                                //remove Item
                                print(item)
                            }
                            self.selectedItem = nil
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
                self.selectedItem = self.piHoleController.piHoles.first
        }
    
    }
}

struct PiHoleConfigView_Previews: PreviewProvider {
    static var previews: some View {
        PiholeConfigView()
    }
}
