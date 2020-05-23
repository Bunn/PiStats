//
//  PreferencesView.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 23/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var preferences: Preferences

    var body: some View {
        Form {
            Toggle(isOn: $preferences.keepPopoverPanelOpen) {
                Text(UIConstants.Strings.keepPopoverOpenPreference)
            }
        }
    }
}

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
