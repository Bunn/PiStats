//
//  LocalNotificationDispatcher.swift
//  PiStats
//
//  Delivers AlertEvents as local user notifications. Works on iOS and macOS.
//

import Foundation
import UserNotifications
import PiStatsCore

/// `AlertNotifying` backed by `UNUserNotificationCenter`. The event's `dedupeKey`
/// is used as the request identifier so re-delivering the same condition simply
/// replaces the pending request rather than stacking duplicates.
public struct LocalNotificationDispatcher: AlertNotifying {
    public init() {}

    /// Requests authorization the first time it's needed. Returns whether
    /// notifications are now allowed.
    @discardableResult
    public func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        default:
            return false
        }
    }

    public func deliver(_ event: AlertEvent) async {
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.body
        content.sound = .default
        content.threadIdentifier = event.piholeID.uuidString
        if event.kind == .blockingDisabled {
            content.categoryIdentifier = LocalNotificationDispatcher.disabledCategoryID
        }
        let request = UNNotificationRequest(identifier: event.dedupeKey, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Category carrying a "Re-enable" action; registered at app launch.
    public static let disabledCategoryID = "PIHOLE_DISABLED"
}
