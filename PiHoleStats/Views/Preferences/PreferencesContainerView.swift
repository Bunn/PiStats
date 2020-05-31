//
//  PreferencesView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PreferencesContainerView: View {
    @State var selectedView = 1
    @EnvironmentObject var piHoleController: PiholeController

    var body: some View {
        VStack {
            TabView(selection: $selectedView) {
                PiholeConfigView()
                    .padding().tabItem {
                        Text(UIConstants.Strings.piHoleTabTitle)
                }.tag(1)
                
                PreferencesView()
                    .padding().tabItem {
                        Text(UIConstants.Strings.preferencesTabTitle)
                }.tag(2)
                
                AboutView()
                    .padding().tabItem {
                        Text(UIConstants.Strings.aboutTabTitle)
                }.tag(3)
                
            }.padding()
        }
    }
}

struct PreferencesContainerView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesContainerView()
    }
}
