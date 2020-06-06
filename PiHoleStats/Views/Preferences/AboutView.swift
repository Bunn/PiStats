//
//  AboutView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI
import Preferences

struct AboutView: View {
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    var body: some View {
        Preferences.Container(contentWidth: 300) {
            [Preferences.Section(title: "") {
                Text(UIConstants.Strings.piStatsName)
                Text("\(UIConstants.Strings.version) \(self.appVersion)")
                Divider()
                Text(UIConstants.Strings.copyright)
                    .font(.caption)
            }]
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
