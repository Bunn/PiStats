//
//  AboutView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var appVersion: String  {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    var body: some View {
        VStack(spacing: 4.0) {
            Image("shieldIcon")
            
            Text(UIConstants.Strings.piStatsName)
                .font(.body)
            
            Text("\(UIConstants.Strings.version) \(appVersion)")
                .font(.caption)
            
            Text(UIConstants.Strings.copyright)
                .font(.caption)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
