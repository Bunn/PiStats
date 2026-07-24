import PiStatsCore

nonisolated protocol WatchPiholeServicing: Sendable {
    var pihole: Pihole { get }

    func fetchSummary() async throws -> PiholeSummary
    func fetchStatus() async throws -> PiholeStatus
    func enable() async throws -> PiholeStatus
    func disable(timer: Int?) async throws -> PiholeStatus
}

extension PiholeAPIClient: WatchPiholeServicing {}
