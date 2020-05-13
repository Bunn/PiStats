//
//  UIConstants.swift
//  PiHoleStats
//
//  Created by Fernando Bunn on 11/05/2020.
//  Copyright © 2020 Fernando Bunn. All rights reserved.
//

import Foundation
import SwiftUI

struct UIConstants {
    
    struct Geometry {
        static let circleSize: CGFloat = 10.0
    }
    
    struct Colors {
        static let offline = Color("offline")
        static let active = Color("active")
        static let totalQuery = Color("totalQuery")
        static let domainBlocked = Color("domainBlocked")
        static let queryBlocked = Color("queryBlocked")
        static let percentBlocked = Color("percentBlocked")
    }
    
    struct Strings {
        static let totalQueries = "Total Queries"
        static let queriesBlocked = "Queries Blocked"
        static let percentBlocked = "Percent Blocked"
        static let domainsOnBlocklist = "Domains on Blocklist"
        static let buttonSettings = "Settings"
        static let buttonQuit = "Quit"
        static let statusEnabled = "Active"
        static let statusDisabled = "Offline"
        static let buttonEnable = "Enable"
        static let buttonDisable = "Disable"
        static let host = "Host"
        static let hostPlaceholder = "0.0.0.0"
        static let apiToken = "API Token"
        static let apiTokenPlaceholder = "klaatubaradanikto"
        static let buttonClose = "Close"
        static let findAPITokenInfo = "You can find the API Token on /etc/pihole/setupVars.conf under WEBPASSWORD"
    }
}
