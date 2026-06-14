//
//  UserDefaultExtensions.swift
//  PiStatsMobile
//
//  Created by Fernando Bunn on 12/07/2020.
//

import Foundation

extension UserDefaults {

    static func shared() -> UserDefaults {
        return UserDefaults(suiteName: AppGroup.name)!
    }

    enum LiveActivity {
        static let enabledKey = "liveActivityEnabled"
    }

    static var isLiveActivityEnabled: Bool {
        shared().object(forKey: LiveActivity.enabledKey) as? Bool ?? true
    }
}
