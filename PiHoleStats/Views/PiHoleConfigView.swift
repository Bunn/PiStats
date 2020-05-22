//
//  ContentView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 25/04/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PiHoleConfigView: View {
    @EnvironmentObject var navigationItem: NavigationViewModel
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        VStack {
            HStack {
                Text(UIConstants.Strings.host)
                TextField(UIConstants.Strings.hostPlaceholder, text: self.$preferences.address)
            }
            
            HStack {
                Text(UIConstants.Strings.apiToken)
                SecureField(UIConstants.Strings.apiTokenPlaceholder, text: self.$preferences.apiToken)
            }
            
            Divider()
            
            Text(UIConstants.Strings.findAPITokenInfo)
                .font(.caption)
                .multilineTextAlignment(.center)
                .layoutPriority(1)
            
            Spacer()
            
            Text(UIConstants.Strings.tokenStoredOnKeychainInfo)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .foregroundColor(.secondary)
            
        }
        .padding()
    }
}


struct PiHoleConfigView_Previews: PreviewProvider {
    static var previews: some View {
        PiHoleConfigView()
    }
}
