import Foundation

/// Per-Pi-hole memory the engine carries between snapshots so alerts are
/// edge-triggered (fire on transition, not every poll) and offline detection
/// can debounce across consecutive failures.
public struct AlertState: Sendable, Equatable {
    public var consecutiveFailures: Int
    public var firingKeys: Set<String>

    public init(consecutiveFailures: Int = 0, firingKeys: Set<String> = []) {
        self.consecutiveFailures = consecutiveFailures
        self.firingKeys = firingKeys
    }
}
