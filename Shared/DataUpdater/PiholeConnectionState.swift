import Foundation

enum PiholeConnectionState: Equatable, Sendable {
    case idle
    case connecting
    case connected
    case stale
    case unavailable
}
