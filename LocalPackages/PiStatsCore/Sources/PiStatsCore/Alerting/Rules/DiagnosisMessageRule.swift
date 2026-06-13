import Foundation

/// Emits one event per FTL diagnostic message. Cross-snapshot dedupe happens in
/// the engine via `dedupeKey`, which is keyed on the message text (the model's
/// `id` is regenerated on every fetch, so it must not be used for identity).
public struct DiagnosisMessageRule: AlertRule {
    public let kind: AlertKind = .ftlMessage
    public init() {}

    public func evaluate(_ c: AlertEvaluationContext) -> [AlertEvent] {
        guard enabled(c), let messages = c.snapshot.health?.messages else { return [] }
        return messages.map { msg in
            AlertEvent(kind: .ftlMessage,
                       piholeID: c.snapshot.piholeID,
                       title: "Pi-hole diagnostic",
                       body: msg.text,
                       timestamp: msg.timestamp,
                       detail: msg.text)
        }
    }
}
