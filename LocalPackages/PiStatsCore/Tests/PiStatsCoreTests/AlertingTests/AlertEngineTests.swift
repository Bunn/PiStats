import Testing
import Foundation
@testable import PiStatsCore

actor MockNotifier: AlertNotifying {
    private(set) var delivered: [AlertEvent] = []
    func deliver(_ event: AlertEvent) async { delivered.append(event) }
}

@Suite struct AlertEngineTests {
    let pid = UUID()

    func snap(reachable: Bool = true, status: PiholeStatus = .enabled, health: PiholeHealth? = nil) -> PiholeSnapshot {
        PiholeSnapshot(piholeID: pid, piholeName: "Home", reachable: reachable, status: status, health: health)
    }

    @Test func doesNotReNotifyWhileFiring() async {
        let notifier = MockNotifier()
        let engine = AlertEngine(rules: [OfflineRule()], notifier: notifier, settings: AlertSettings(masterEnabled: true, offlineFailureThreshold: 1))
        await engine.ingest(snap(reachable: false))   // failure 1 -> threshold 1 -> fires
        await engine.ingest(snap(reachable: false))   // still failing -> already firing -> no new
        let count = await notifier.delivered.count
        #expect(count == 1)
    }

    @Test func recoveryClearsFiringSoOfflineCanFireAgain() async {
        let notifier = MockNotifier()
        let engine = AlertEngine(rules: [OfflineRule(), RecoveryRule()], notifier: notifier, settings: AlertSettings(masterEnabled: true, offlineFailureThreshold: 1))
        await engine.ingest(snap(reachable: false))   // offline fires
        await engine.ingest(snap(reachable: true))    // recovery fires, clears offline firing
        await engine.ingest(snap(reachable: false))   // offline fires again
        let kinds = await notifier.delivered.map { $0.kind }
        #expect(kinds == [.unreachable, .recovered, .unreachable])
    }

    @Test func distinctFtlMessagesEachNotifyOnce() async {
        let notifier = MockNotifier()
        let engine = AlertEngine(rules: [DiagnosisMessageRule()], notifier: notifier, settings: AlertSettings(masterEnabled: true))
        let h1 = PiholeHealth(coreVersion: nil, webVersion: nil, ftlVersion: nil, updateAvailable: false, messages: [DiagnosisMessage(text: "A")])
        let h2 = PiholeHealth(coreVersion: nil, webVersion: nil, ftlVersion: nil, updateAvailable: false, messages: [DiagnosisMessage(text: "A"), DiagnosisMessage(text: "B")])
        await engine.ingest(snap(health: h1))  // A
        await engine.ingest(snap(health: h2))  // A already fired -> only B
        let details = await notifier.delivered.compactMap { $0.detail }
        #expect(details == ["A", "B"])
    }

    @Test func blockingDisabledReFiresAfterReEnable() async {
        let notifier = MockNotifier()
        let engine = AlertEngine(rules: [BlockingDisabledRule()], notifier: notifier, settings: AlertSettings(masterEnabled: true))
        await engine.ingest(snap(status: .enabled))
        await engine.ingest(snap(status: .disabled))  // fires
        await engine.ingest(snap(status: .enabled))   // clears
        await engine.ingest(snap(status: .disabled))  // fires again
        let count = await notifier.delivered.count
        #expect(count == 2)
    }

    @Test func multiplePiholesTrackedIndependently() async {
        let notifier = MockNotifier()
        let engine = AlertEngine(rules: [OfflineRule()], notifier: notifier, settings: AlertSettings(masterEnabled: true, offlineFailureThreshold: 1))
        let a = UUID(), b = UUID()
        await engine.ingest(PiholeSnapshot(piholeID: a, piholeName: "A", reachable: false, status: .unknown, health: nil))
        await engine.ingest(PiholeSnapshot(piholeID: b, piholeName: "B", reachable: false, status: .unknown, health: nil))
        let count = await notifier.delivered.count
        #expect(count == 2)
    }
}
