//
//  PreferencesView.swift
//  PiStats (macOS)
//
//  Created by Fernando Bunn on 05/02/2022.
//

import SwiftUI

struct PreferencesView: View {
    
    @State var launchAtLogonPreference: Bool = false
    @State var displayDisableTimeOptions: Bool = false
    
    var body: some View {
        VStack (alignment: .leading) {
            Toggle(isOn: $launchAtLogonPreference) {
                Text("Launch at Login")
            }
            Toggle(isOn: $displayDisableTimeOptions) {
                Text("Display disable time options")
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
