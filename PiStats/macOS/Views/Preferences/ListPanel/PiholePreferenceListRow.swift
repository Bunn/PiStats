//
//  PiholePreferenceListRow.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 01/03/2022.
//

import SwiftUI
import PiStatsCore

struct PiholePreferenceListRow: View {
    let pihole: Pihole
    
    var body: some View {
        HStack {
            HStack {
                ZStack {
                    
                    RoundedRectangle(cornerRadius: 10)
                    
                        .frame(width: 35, height: 35)
                        .shadow(radius: 1)
                        .padding(8)
                    
                    Image(systemName: "shield")
                        .renderingMode(.original)
                        .font(.title2)
                        .foregroundColor(.white)
                        .shadow(radius: 1)
                }
                
                VStack (alignment: .leading) {
                    Text(pihole.address)
                        .font(.title3)
                    Text(pihole.enabled ? "Enabled" : "Disabled")
                        .font(.caption)
                }
            }
            
            
            Spacer()
            
        }.contentShape(Rectangle())    }
}

struct PiholePreferenceListRow_Previews: PreviewProvider {
    static var previews: some View {
        PiholePreferenceListRow(pihole: Pihole.preview())
    }
}
