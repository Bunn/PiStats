//
//  PiholeActionService.swift
//  PiStats
//
//  One enable/disable code path shared by the app, the widget toggle intent,
//  the Control Center control and the Live Activity re-enable action.
//

import Foundation
import PiStatsCore

struct PiholeActionService {
    /// Invoked after a successful timed disable so iOS can start a Live Activity.
    /// macOS / contexts without Live Activities pass `nil`.
    typealias DisableStarted = @Sendable (_ piholeID: UUID, _ name: String, _ until: Date) -> Void

    private let onDisableWithTimer: DisableStarted?

    init(onDisableWithTimer: DisableStarted? = nil) {
        self.onDisableWithTimer = onDisableWithTimer
    }

    @discardableResult
    func toggle(_ pihole: Pihole) async throws -> PiholeStatus {
        let client = PiholeAPIClient(pihole)
        let current = try await client.fetchStatus()
        return current == .enabled ? try await disable(pihole, timer: nil) : try await enable(pihole)
    }

    @discardableResult
    func disable(_ pihole: Pihole, timer: Int?) async throws -> PiholeStatus {
        let status = try await PiholeAPIClient(pihole).disable(timer: timer)
        if let timer, status == .disabled {
            onDisableWithTimer?(pihole.uuid, pihole.name, Date().addingTimeInterval(TimeInterval(timer)))
        }
        return status
    }

    @discardableResult
    func enable(_ pihole: Pihole) async throws -> PiholeStatus {
        try await PiholeAPIClient(pihole).enable()
    }
}
