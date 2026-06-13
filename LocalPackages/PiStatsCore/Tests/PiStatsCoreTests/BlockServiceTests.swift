//
//  BlockServiceTests.swift
//  PiStatsCoreTests
//
//  Tests for the block-whole-service catalog. The underlying deny-regex network
//  operations now go through the generic domain API and are covered by
//  DomainManagementTests (kind: .regex).
//

import Testing
import Foundation
@testable import PiStatsCore

@Suite("Block Service Tests")
struct BlockServiceTests {

    @Test("BlockableService.isBlocked requires every rule present")
    func testIsBlocked() {
        let service = BlockableService(id: "t", name: "T", systemImage: "x", rules: ["a", "b"])
        #expect(service.isBlocked(in: ["a", "b", "c"]) == true)
        #expect(service.isBlocked(in: ["a"]) == false)
        #expect(service.isBlocked(in: []) == false)
        #expect(BlockableService.catalog.isEmpty == false)
        #expect(BlockableService.catalog.allSatisfy { !$0.rules.isEmpty })
    }
}
