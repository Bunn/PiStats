import Foundation

/// Evaluates `PiholeSnapshot`s against a set of `AlertRule`s and forwards new,
/// deduped `AlertEvent`s to a notifier. Alerts are edge-triggered: a condition
/// notifies once when it starts and (for offline) once when it clears, rather
/// than on every poll cycle. State is kept per Pi-hole.
public actor AlertEngine {
    private let rules: [any AlertRule]
    private let notifier: AlertNotifying
    private var settings: AlertSettings
    private var states: [UUID: AlertState] = [:]
    private var lastSnapshots: [UUID: PiholeSnapshot] = [:]

    public init(rules: [any AlertRule], notifier: AlertNotifying, settings: AlertSettings) {
        self.rules = rules
        self.notifier = notifier
        self.settings = settings
    }

    /// The full set of built-in rules, in evaluation order.
    public static var defaultRules: [any AlertRule] {
        [OfflineRule(), RecoveryRule(), BlockingDisabledRule(), UpdateAvailableRule(), DiagnosisMessageRule()]
    }

    public func update(settings: AlertSettings) { self.settings = settings }

    public func ingest(_ snapshot: PiholeSnapshot) async {
        let id = snapshot.piholeID
        var state = states[id] ?? AlertState()
        let previous = lastSnapshots[id]

        // Debounce counter for offline detection.
        state.consecutiveFailures = snapshot.reachable ? 0 : state.consecutiveFailures + 1

        let context = AlertEvaluationContext(snapshot: snapshot, previous: previous, state: state, settings: settings)

        let unreachableKey = "\(id.uuidString):\(AlertKind.unreachable.rawValue)"
        var firing = state.firingKeys

        for rule in rules {
            for event in rule.evaluate(context) {
                let key = event.dedupeKey
                if event.kind == .recovered {
                    // Recovery clears the matching offline firing so it can fire again later.
                    firing.remove(unreachableKey)
                    await notifier.deliver(event)
                } else if !state.firingKeys.contains(key) {
                    firing.insert(key)
                    await notifier.deliver(event)
                }
            }
        }

        // Clear edge-state keys whose condition no longer holds so they can re-fire.
        if snapshot.reachable { firing.remove(unreachableKey) }
        if snapshot.status != .disabled { firing.remove("\(id.uuidString):\(AlertKind.blockingDisabled.rawValue)") }
        if snapshot.health?.updateAvailable != true { firing.remove("\(id.uuidString):\(AlertKind.updateAvailable.rawValue)") }

        state.firingKeys = firing
        states[id] = state
        lastSnapshots[id] = snapshot
    }
}
