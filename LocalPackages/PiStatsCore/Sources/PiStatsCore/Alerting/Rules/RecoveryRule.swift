import Foundation

/// Fires when a Pi-hole that was previously unreachable becomes reachable again.
public struct RecoveryRule: AlertRule {
    public let kind: AlertKind = .recovered
    public init() {}

    public func evaluate(_ c: AlertEvaluationContext) -> [AlertEvent] {
        guard enabled(c), c.snapshot.reachable, c.previous?.reachable == false else { return [] }
        return [AlertEvent(kind: .recovered,
                           piholeID: c.snapshot.piholeID,
                           title: "\(c.snapshot.piholeName) is back online",
                           body: "Connection restored.",
                           timestamp: nil)]
    }
}
