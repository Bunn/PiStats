import Testing
import Foundation
@testable import PiStatsCore

@Suite struct RuleTests {
    let pid = UUID()

    func snap(reachable: Bool = true, status: PiholeStatus = .enabled, health: PiholeHealth? = nil) -> PiholeSnapshot {
        PiholeSnapshot(piholeID: pid, piholeName: "Home", reachable: reachable, status: status, health: health)
    }

    func ctx(_ s: PiholeSnapshot,
             prev: PiholeSnapshot?,
             state: AlertState = AlertState(),
             settings: AlertSettings = AlertSettings(masterEnabled: true)) -> AlertEvaluationContext {
        AlertEvaluationContext(snapshot: s, previous: prev, state: state, settings: settings)
    }

    @Test func offlineFiresOnlyAfterThreshold() {
        let rule = OfflineRule()
        // below threshold (2): no event
        #expect(rule.evaluate(ctx(snap(reachable: false), prev: snap(), state: AlertState(consecutiveFailures: 1))).isEmpty)
        // at threshold: fires
        let events = rule.evaluate(ctx(snap(reachable: false), prev: snap(), state: AlertState(consecutiveFailures: 2)))
        #expect(events.count == 1)
        #expect(events.first?.kind == .unreachable)
    }

    @Test func recoveryFiresOnTransitionBackToReachable() {
        let rule = RecoveryRule()
        #expect(rule.evaluate(ctx(snap(reachable: true), prev: snap(reachable: false))).first?.kind == .recovered)
        #expect(rule.evaluate(ctx(snap(reachable: true), prev: snap(reachable: true))).isEmpty)
    }

    @Test func blockingDisabledFiresOnEdge() {
        let rule = BlockingDisabledRule()
        #expect(rule.evaluate(ctx(snap(status: .disabled), prev: snap(status: .enabled))).first?.kind == .blockingDisabled)
        #expect(rule.evaluate(ctx(snap(status: .disabled), prev: snap(status: .disabled))).isEmpty)
    }

    @Test func updateAvailableFiresOnEdge() {
        let rule = UpdateAvailableRule()
        let withUpdate = PiholeHealth(coreVersion: "1", webVersion: "1", ftlVersion: "1", updateAvailable: true, messages: [])
        let noUpdate = PiholeHealth(coreVersion: "1", webVersion: "1", ftlVersion: "1", updateAvailable: false, messages: [])
        #expect(rule.evaluate(ctx(snap(health: withUpdate), prev: snap(health: noUpdate))).first?.kind == .updateAvailable)
        #expect(rule.evaluate(ctx(snap(health: withUpdate), prev: snap(health: withUpdate))).isEmpty)
    }

    @Test func ftlMessageEmitsPerMessageKeyedOnText() {
        let rule = DiagnosisMessageRule()
        let h = PiholeHealth(coreVersion: nil, webVersion: nil, ftlVersion: nil, updateAvailable: false,
                             messages: [DiagnosisMessage(text: "A"), DiagnosisMessage(text: "B")])
        let events = rule.evaluate(ctx(snap(health: h), prev: snap(health: nil)))
        #expect(events.count == 2)
        #expect(Set(events.compactMap { $0.detail }) == ["A", "B"])
        #expect(events.allSatisfy { $0.kind == .ftlMessage })
    }

    @Test func disabledSettingSuppressesRule() {
        var settings = AlertSettings(masterEnabled: true)
        settings.setEnabled(false, for: .blockingDisabled)
        let rule = BlockingDisabledRule()
        #expect(rule.evaluate(ctx(snap(status: .disabled), prev: snap(status: .enabled), settings: settings)).isEmpty)
    }
}
