//
//  NotificationActionHandler.swift
//  PiStats
//
//  Registers the "blocking disabled" notification category and handles its
//  Re-enable action by turning blocking back on. Also presents banners while
//  the app is foregrounded. Works on iOS and macOS.
//

import Foundation
import UserNotifications
import PiStatsCore

final class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationActionHandler()
    static let reenableActionID = "REENABLE_BLOCKING"

    /// Registers categories and installs this object as the notification delegate.
    func registerCategories() {
        let reenable = UNNotificationAction(identifier: Self.reenableActionID,
                                            title: "Re-enable",
                                            options: [.authenticationRequired])
        let category = UNNotificationCategory(identifier: LocalNotificationDispatcher.disabledCategoryID,
                                              actions: [reenable],
                                              intentIdentifiers: [],
                                              options: [])
        let center = UNUserNotificationCenter.current()
        center.setNotificationCategories([category])
        center.delegate = self
    }

    // Show alerts even while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard response.actionIdentifier == Self.reenableActionID else { return }
        let idString = response.notification.request.content.threadIdentifier
        guard let uuid = UUID(uuidString: idString),
              let pihole = DefaultPiholeStorage().restorePihole(uuid) else { return }
        _ = try? await PiholeActionService().enable(pihole)
    }
}
