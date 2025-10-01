import Foundation
import Combine
import SwiftUI
import PiStatsCore

@MainActor
final class MacPiholesModel: ObservableObject {
    @Published private(set) var items: [Item] = []

    struct Item: Identifiable {
        let id = UUID()
        let pihole: Pihole
        var summary: Summary
    }

    struct Summary {
        var name: String
        var totalQueries: String = "0"
        var queriesBlocked: String = "0"
        var percentageBlocked: String = "0%"
        var status: PiholeStatus = .unknown
        var hasError: Bool = false
    }

    private var timers: [UUID: Timer] = [:]

    func start() {
        load()
        Task { for index in items.indices { await refresh(at: index) } }
        scheduleTimers()
    }

    func stop() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()
    }

    func reload() {
        stop()
        start()
    }
    
    func delete(item: Item) {
        // Remove from storage
        let storage = DefaultPiholeStorage()
        storage.deletePihole(item.pihole)
        
        // Remove from local items
        items.removeAll { $0.id == item.id }
        
        // Stop timer for deleted item
        if let timer = timers[item.pihole.uuid] {
            timer.invalidate()
            timers.removeValue(forKey: item.pihole.uuid)
        }
    }

    private func load() {
        let list = DefaultPiholeStorage().restoreAllPiholes()
        self.items = list.map { p in
            Item(pihole: p, summary: Summary(name: p.name))
        }
    }

    private func scheduleTimers() {
        stop()
        for i in items.indices {
            let id = items[i].pihole.uuid
            let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
                Task { await self?.refresh(at: i) }
            }
            timers[id] = timer
        }
    }

    private func refresh(at index: Int) async {
        guard items.indices.contains(index) else { return }
        let p = items[index].pihole
        let client = PiholeAPIClient(p)
        do {
            let (summary, status) = try await (
                client.fetchSummary(),
                client.fetchStatus()
            )
            var s = items[index].summary
            s.totalQueries = summary.queries.formatted()
            s.queriesBlocked = summary.adsBlocked.formatted()
            s.percentageBlocked = summary.adsPercentageToday.formattedPercentage()
            s.status = status
            s.hasError = false
            items[index].summary = s
        } catch {
            var s = items[index].summary
            s.status = .unknown
            s.hasError = true
            items[index].summary = s
        }
    }
}

