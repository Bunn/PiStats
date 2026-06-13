import Foundation

/// Everything a rule needs to decide whether to raise an alert for one Pi-hole:
/// the current snapshot, the previous one (for edge detection), the engine's
/// running state (for debounce), and the user's settings.
public struct AlertEvaluationContext: Sendable {
    public let snapshot: PiholeSnapshot
    public let previous: PiholeSnapshot?
    public let state: AlertState
    public let settings: AlertSettings

    public init(snapshot: PiholeSnapshot,
                previous: PiholeSnapshot?,
                state: AlertState,
                settings: AlertSettings) {
        self.snapshot = snapshot
        self.previous = previous
        self.state = state
        self.settings = settings
    }
}
