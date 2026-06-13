import Foundation

/// Fires once the Pi-hole has been unreachable for `offlineFailureThreshold`
/// consecutive cycles (debounced to avoid flapping on a single missed poll).
public struct OfflineRule: AlertRule {
    public let kind: AlertKind = .unreachable
    public init() {}

    public func evaluate(_ c: AlertEvaluationContext) -> [AlertEvent] {
        guard enabled(c), !c.snapshot.reachable,
              c.state.consecutiveFailures >= c.settings.offlineFailureThreshold else { return [] }
        return [AlertEvent(kind: .unreachable,
                           piholeID: c.snapshot.piholeID,
                           title: "\(c.snapshot.piholeName) is offline",
                           body: "PiStats couldn't reach this Pi-hole.",
                           timestamp: nil)]
    }
}
