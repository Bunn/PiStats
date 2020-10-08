//
//  PreferencesView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 23/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI
import Preferences

struct PreferencesView: View {
    @EnvironmentObject var preferences: UserPreferences
    
    var body: some View {
        Preferences.Container(contentWidth: 300) {
            Preferences.Section(title: "") {
                Toggle(isOn: self.$preferences.keepPopoverPanelOpen) {
                    Text(UIConstants.Strings.keepPopoverOpenPreference)
                }
                Toggle(isOn: self.$preferences.launchAtLoginEnabled) {
                    Text(UIConstants.Strings.launchAtLogonPreference)
                }
                Toggle(isOn: self.$preferences.displayDisableTimeOptions) {
                    Text(UIConstants.Strings.disableTimeOptionsTitle)
                }
                Toggle(isOn: self.$preferences.displayStatusColorWhenPiholeIsOffline) {
                    Text(UIConstants.Strings.displayStatusColorWhenPiholeIsOffline)
                }
                }
            
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
