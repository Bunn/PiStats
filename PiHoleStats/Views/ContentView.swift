//
//  ContentView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var navigationItem: NavigationViewModel

    @ViewBuilder
    var body: some View {
        if navigationItem.currentNavigationItem == .settings {
            PiHoleConfigView()
        } else {
            SummaryView()
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
