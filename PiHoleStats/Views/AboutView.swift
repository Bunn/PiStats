//
//  AboutView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 22/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 4.0) {
            Image("shieldIcon")
            
            Text(UIConstants.Strings.aboutTitle)
                .font(.body)
            
            Text("\(UIConstants.Strings.version) 1.0.0")
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
