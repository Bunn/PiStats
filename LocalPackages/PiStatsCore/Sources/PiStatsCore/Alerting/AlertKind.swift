import Foundation

/// The taxonomy of conditions PiStats can alert the user about.
public enum AlertKind: String, Sendable, CaseIterable, Codable {
    case unreachable
    case recovered
    case blockingDisabled
    case updateAvailable
    case ftlMessage
}
