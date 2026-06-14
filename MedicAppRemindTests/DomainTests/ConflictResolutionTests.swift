//
//  ConflictResolutionTests.swift
//  MedicAppRemindTests
//
//  F7.S2 — Smoke tests for `Medication.resolvingConflict(with:)`. Two snapshots
//  of the same medication merge to the one with the later `updatedAt`; an exact
//  tie keeps the local version. Pure domain: no UI, no store, no CloudKit.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Medication conflict resolution (last-write-wins)")
struct ConflictResolutionTests {

    private let base = Date(timeIntervalSinceReferenceDate: 0)

    @Test("Remote edited later wins")
    func remoteNewerWins() {
        let local = makeMedication(currentStock: 10, updatedAt: base)
        let remote = makeMedication(currentStock: 3, updatedAt: base.addingTimeInterval(60))
        let winner = local.resolvingConflict(with: remote)
        #expect(winner == remote)
        #expect(winner.currentStock == 3)
    }

    @Test("Local edited later wins")
    func localNewerWins() {
        let local = makeMedication(currentStock: 10, updatedAt: base.addingTimeInterval(60))
        let remote = makeMedication(currentStock: 3, updatedAt: base)
        let winner = local.resolvingConflict(with: remote)
        #expect(winner == local)
        #expect(winner.currentStock == 10)
    }

    @Test("Exact updatedAt tie keeps the local version")
    func tieKeepsLocal() {
        let local = makeMedication(currentStock: 10, updatedAt: base)
        let remote = makeMedication(currentStock: 3, updatedAt: base)
        let winner = local.resolvingConflict(with: remote)
        #expect(winner == local)
        #expect(winner.currentStock == 10)
    }
}
