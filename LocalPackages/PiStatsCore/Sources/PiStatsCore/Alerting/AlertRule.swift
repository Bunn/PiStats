import Foundation

/// A single, isolated alerting condition. Add a new alert by adding a new
/// `AlertRule` type — nothing else in the engine changes.
public protocol AlertRule: Sendable {
    var kind: AlertKind { get }
    func evaluate(_ context: AlertEvaluationContext) -> [AlertEvent]
}

extension AlertRule {
    /// Rules return `[]` when their kind is switched off in settings.
    func enabled(_ context: AlertEvaluationContext) -> Bool { context.settings.isEnabled(kind) }
}
