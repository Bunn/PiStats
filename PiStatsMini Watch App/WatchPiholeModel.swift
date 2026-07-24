import Foundation
import Observation
import PiStatsCore

@MainActor
@Observable
final class WatchPiholeModel: Identifiable {
    let pihole: Pihole

    private(set) var summary: PiholeSummary?
    private(set) var status: PiholeStatus = .unknown
    private(set) var isRefreshing = false
    private(set) var isPerformingAction = false
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?
    private(set) var actionCompletionID = 0

    @ObservationIgnored
    private let service: any WatchPiholeServicing

    var id: UUID {
        pihole.uuid
    }

    init(
        pihole: Pihole,
        service: (any WatchPiholeServicing)? = nil
    ) {
        self.pihole = pihole
        self.service = service ?? PiholeAPIClient(pihole)
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let service = service
        async let summaryOutcome = Self.capture {
            try await service.fetchSummary()
        }
        async let statusOutcome = Self.capture {
            try await service.fetchStatus()
        }

        let (newSummary, newStatus) = await (summaryOutcome, statusOutcome)
        var errors: [String] = []
        var receivedData = false

        switch newSummary {
        case .success(let value):
            summary = value
            receivedData = true
        case .failure(let message):
            errors.append(message)
        }

        switch newStatus {
        case .success(let value):
            status = value
            receivedData = true
        case .failure(let message):
            errors.append(message)
        }

        if receivedData {
            lastUpdated = .now
        }
        errorMessage = errors.first
    }

    func enable() async {
        await performAction {
            try await service.enable()
        }
    }

    func disable(timer: Int?) async {
        await performAction {
            try await service.disable(timer: timer)
        }
    }

    private func performAction(
        _ action: () async throws -> PiholeStatus
    ) async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }

        do {
            status = try await action()
            errorMessage = nil
            lastUpdated = .now
            actionCompletionID &+= 1
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private enum FetchOutcome<Value: Sendable>: Sendable {
        case success(Value)
        case failure(String)
    }

    private nonisolated static func capture<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async -> FetchOutcome<Value> {
        do {
            return .success(try await operation())
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
