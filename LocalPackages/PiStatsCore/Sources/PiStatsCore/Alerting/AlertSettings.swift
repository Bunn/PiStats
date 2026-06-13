import Foundation

/// User-controlled alerting preferences. Stored in the shared app group so the
/// app, widget and Control Center control all read the same values.
public struct AlertSettings: Codable, Sendable, Equatable {
    public var masterEnabled: Bool
    public var offlineFailureThreshold: Int
    private var disabledKinds: Set<AlertKind>

    public init(masterEnabled: Bool = false,
                offlineFailureThreshold: Int = 2,
                disabledKinds: Set<AlertKind> = []) {
        self.masterEnabled = masterEnabled
        self.offlineFailureThreshold = offlineFailureThreshold
        self.disabledKinds = disabledKinds
    }

    public static let `default` = AlertSettings()

    public func isEnabled(_ kind: AlertKind) -> Bool {
        masterEnabled && !disabledKinds.contains(kind)
    }

    public mutating func setEnabled(_ enabled: Bool, for kind: AlertKind) {
        if enabled { disabledKinds.remove(kind) } else { disabledKinds.insert(kind) }
    }
}
