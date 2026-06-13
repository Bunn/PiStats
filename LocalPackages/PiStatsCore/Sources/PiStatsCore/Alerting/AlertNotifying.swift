import Foundation

/// Delivers an alert to the user. Implemented by `LocalNotificationDispatcher`
/// in the app layer; a future push relay would be another conformer.
public protocol AlertNotifying: Sendable {
    func deliver(_ event: AlertEvent) async
}
