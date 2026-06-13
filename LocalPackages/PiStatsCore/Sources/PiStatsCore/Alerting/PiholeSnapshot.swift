import Foundation

/// Immutable input the `AlertEngine` evaluates for one Pi-hole at one moment.
/// Built by the platform monitoring drivers from a completed poll (macOS) or a
/// background health check (iOS).
public struct PiholeSnapshot: Sendable {
    public let piholeID: UUID
    public let piholeName: String
    public let reachable: Bool
    public let status: PiholeStatus
    public let health: PiholeHealth?

    public init(piholeID: UUID,
                piholeName: String,
                reachable: Bool,
                status: PiholeStatus,
                health: PiholeHealth?) {
        self.piholeID = piholeID
        self.piholeName = piholeName
        self.reachable = reachable
        self.status = status
        self.health = health
    }
}
