import Foundation

/// An alert the engine decided to raise. `dedupeKey` makes the event idempotent
/// so the same condition is not re-notified on every poll cycle.
public struct AlertEvent: Sendable, Equatable {
    public let kind: AlertKind
    public let piholeID: UUID
    public let title: String
    public let body: String
    public let timestamp: Date?
    /// Extra disambiguator (e.g. an FTL message's text) folded into `dedupeKey`.
    public let detail: String?

    public init(kind: AlertKind,
                piholeID: UUID,
                title: String,
                body: String,
                timestamp: Date?,
                detail: String? = nil) {
        self.kind = kind
        self.piholeID = piholeID
        self.title = title
        self.body = body
        self.timestamp = timestamp
        self.detail = detail
    }

    public var dedupeKey: String {
        var key = "\(piholeID.uuidString):\(kind.rawValue)"
        if let detail { key += ":\(detail)" }
        return key
    }
}
