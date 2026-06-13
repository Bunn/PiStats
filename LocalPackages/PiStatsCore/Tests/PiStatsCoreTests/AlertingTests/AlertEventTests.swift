import Testing
import Foundation
@testable import PiStatsCore

@Suite struct AlertEventTests {
    @Test func dedupeKeyCombinesPiholeAndKind() {
        let id = UUID()
        let e = AlertEvent(kind: .unreachable, piholeID: id, title: "t", body: "b", timestamp: Date(timeIntervalSince1970: 0))
        #expect(e.dedupeKey == "\(id.uuidString):unreachable")
    }

    @Test func ftlDedupeKeyIncludesMessageText() {
        let id = UUID()
        let e = AlertEvent(kind: .ftlMessage, piholeID: id, title: "t", body: "b", timestamp: nil, detail: "DNSMASQ_WARN")
        #expect(e.dedupeKey == "\(id.uuidString):ftlMessage:DNSMASQ_WARN")
    }
}
