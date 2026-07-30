struct PiholeConfigurationSyncOptions: Sendable, Equatable {
    let configuredPiholeCount: Int
    let automaticallySyncsChanges: Bool

    var requiresScopeConfirmation: Bool {
        configuredPiholeCount > 1 && !automaticallySyncsChanges
    }

    var automaticScope: PiholeConfigurationChangeScope {
        configuredPiholeCount > 1 && automaticallySyncsChanges ? .allPiholes : .currentPihole
    }
}
