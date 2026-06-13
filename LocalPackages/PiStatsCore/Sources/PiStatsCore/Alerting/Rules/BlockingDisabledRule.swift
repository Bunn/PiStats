import Foundation

/// Fires on the edge where blocking transitions into the disabled state.
public struct BlockingDisabledRule: AlertRule {
    public let kind: AlertKind = .blockingDisabled
    public init() {}

    public func evaluate(_ c: AlertEvaluationContext) -> [AlertEvent] {
        guard enabled(c), c.snapshot.status == .disabled, c.previous?.status != .disabled else { return [] }
        return [AlertEvent(kind: .blockingDisabled,
                           piholeID: c.snapshot.piholeID,
                           title: "Blocking disabled",
                           body: "\(c.snapshot.piholeName) is no longer blocking ads & trackers.",
                           timestamp: nil)]
    }
}
