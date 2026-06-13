import Foundation

/// Fires on the edge where a Pi-hole update first becomes available.
public struct UpdateAvailableRule: AlertRule {
    public let kind: AlertKind = .updateAvailable
    public init() {}

    public func evaluate(_ c: AlertEvaluationContext) -> [AlertEvent] {
        guard enabled(c), c.snapshot.health?.updateAvailable == true,
              c.previous?.health?.updateAvailable != true else { return [] }
        return [AlertEvent(kind: .updateAvailable,
                           piholeID: c.snapshot.piholeID,
                           title: "Update available",
                           body: "A Pi-hole update is available for \(c.snapshot.piholeName).",
                           timestamp: nil)]
    }
}
