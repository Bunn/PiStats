import Testing
import Foundation
@testable import PiStatsCore

@Suite struct AlertSettingsTests {
    @Test func defaultDisablesNotificationsButKeepsThresholdTwo() {
        let s = AlertSettings.default
        #expect(s.masterEnabled == false)
        #expect(s.offlineFailureThreshold == 2)
        // Notifications are opt-in: nothing is enabled while the master switch is off.
        for kind in AlertKind.allCases { #expect(s.isEnabled(kind) == false) }
    }

    @Test func enablingMasterTurnsAllKindsOn() {
        var s = AlertSettings.default
        s.masterEnabled = true
        for kind in AlertKind.allCases { #expect(s.isEnabled(kind) == true) }
    }

    @Test func disablingOneKindKeepsOthers() {
        var s = AlertSettings(masterEnabled: true)
        s.setEnabled(false, for: .ftlMessage)
        #expect(s.isEnabled(.ftlMessage) == false)
        #expect(s.isEnabled(.unreachable) == true)
    }

    @Test func masterOffDisablesEverything() {
        var s = AlertSettings.default
        s.masterEnabled = false
        #expect(s.isEnabled(.unreachable) == false)
    }

    @Test func roundTripsThroughCodable() throws {
        var s = AlertSettings.default
        s.setEnabled(false, for: .updateAvailable)
        s.offlineFailureThreshold = 3
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(AlertSettings.self, from: data)
        #expect(decoded == s)
    }
}
