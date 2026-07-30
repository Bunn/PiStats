import Foundation

struct PiholeConfigurationSyncError: LocalizedError, Sendable {
    struct Failure: Sendable {
        let piholeName: String
        let errorDescription: String
    }

    let currentPiholeName: String
    let failures: [Failure]

    var currentPiholeWasUpdated: Bool {
        true
    }

    var errorDescription: String? {
        let failureDetails = failures.map {
            "\($0.piholeName) (\($0.errorDescription))"
        }.formatted()
        return String(
            localized: "The change was saved to \(currentPiholeName), but couldn't be saved to \(failureDetails)."
        )
    }
}
