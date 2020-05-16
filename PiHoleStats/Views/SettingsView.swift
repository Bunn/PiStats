//
//  ContentView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var navigationItem: NavigationViewModel
    @EnvironmentObject var settings: Settings

    var body: some View {
        VStack {
            HStack {
                Text(UIConstants.Strings.host)
                TextField(UIConstants.Strings.hostPlaceholder, text: self.$settings.host)
            }
            
            HStack {
                Text(UIConstants.Strings.apiToken)
                TextField(UIConstants.Strings.apiTokenPlaceholder, text: self.$settings.apiToken)
            }
            
            Button(action: {
                self.navigationItem.currentNavigationItem = .summary
            }) {
                Text(UIConstants.Strings.buttonClose)
            }
            
            Divider()
            
            Text(UIConstants.Strings.findAPITokenInfo)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
