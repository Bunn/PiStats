//
//  PiHoleItemConfig.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 30/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PiholeItemConfigView: View {
    @EnvironmentObject var piHoleController: PiholeController
    @ObservedObject var piholeViewModel: PiholeViewModel
    
    var body: some View {
        VStack {
            HStack {
                Text(UIConstants.Strings.host)
                TextField(UIConstants.Strings.hostPlaceholder, text: $piholeViewModel.address)
            }
            
            HStack {
                Text(UIConstants.Strings.apiToken)
                SecureField(UIConstants.Strings.apiTokenPlaceholder, text: $piholeViewModel.address)
            }
            
            Button(action: {
                self.save()
            }, label: {
                Text("Save")
            })
            
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
    }
    
    private func save() {
        self.piHoleController.objectWillChange.send()
        self.piholeViewModel.save()
    }
}

//struct PiHoleItemConfig_Previews: PreviewProvider {
//    static var previews: some View {
//        PiHoleItemConfig()
//    }
//}
