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

    // MARK: - Acting on every Pi-hole

    func areAllEnabled(_ piholes: [Pihole]) async -> Bool {
        guard !piholes.isEmpty else { return false }
        let statuses = await withTaskGroup(of: PiholeStatus.self) { group -> [PiholeStatus] in
            for pihole in piholes {
                group.addTask { (try? await PiholeAPIClient(pihole).fetchStatus()) ?? .unknown }
            }
            var results: [PiholeStatus] = []
            for await status in group { results.append(status) }
            return results
        }
        return !statuses.contains(.disabled)
    }

    func enableAll(_ piholes: [Pihole]) async throws {
        try await forEachPihole(piholes) { try await enable($0) }
    }

    func disableAll(_ piholes: [Pihole], timer: Int?) async throws {
        try await forEachPihole(piholes) { try await disable($0, timer: timer) }
    }

    private func forEachPihole(_ piholes: [Pihole],
                               _ action: @Sendable @escaping (Pihole) async throws -> Void) async throws {
        guard !piholes.isEmpty else { return }
        let errors = await withTaskGroup(of: Error?.self) { group -> [Error] in
            for pihole in piholes {
                group.addTask {
                    do { try await action(pihole); return nil } catch { return error }
                }
            }
            var collected: [Error] = []
            for await error in group where error != nil { collected.append(error!) }
            return collected
        }
        if errors.count == piholes.count, let first = errors.first { throw first }
    }
}
