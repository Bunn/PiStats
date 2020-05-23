//
//  PreferencesView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @State var selectedView = 1
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        VStack {
            TabView(selection: $selectedView) {
                PiHoleConfigView()
                    .padding().tabItem {
                        Text(UIConstants.Strings.piHoleTabTitle)
                }.tag(1)
                
                AboutView()
                    .padding().tabItem {
                        Text(UIConstants.Strings.aboutTabTitle)
                }.tag(2)
                
            }.padding()
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
