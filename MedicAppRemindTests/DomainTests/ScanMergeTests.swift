//
//  ScanMergeTests.swift
//  MedicAppRemindTests
//
//  FX.S4 — The scan-merge decision is a pure reducer over the scanned box and the
//  store's current state, and the nearest-expiry rule is pure date math. Every test
//  fixes an input and asserts a hand-computed decision.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ScanMerge")
struct ScanMergeTests {

    @Test("An unknown national code decides to create, seeding the scanned units")
    func createsWhenNationalCodeIsNew() {
        // No stored state matches the code → create a medication with the box's units.
        let decision = scanMergeDecision(serial: "SN-1", units: 20, against: nil)
        #expect(decision == .create(units: 20))
    }

    @Test("A new serial on an existing medication decides to add stock")
    func addsStockForNewSerial() {
        // The medication exists (a serial already recorded) and this box is new.
        let stored = StoredBoxState(recordedSerials: ["SN-1"])
        let decision = scanMergeDecision(serial: "SN-2", units: 20, against: stored)
        #expect(decision == .addStock(units: 20))
    }

    @Test("An already-recorded serial decides the box is a duplicate")
    func duplicateWhenSerialAlreadyRecorded() {
        let stored = StoredBoxState(recordedSerials: ["SN-1", "SN-2"])
        let decision = scanMergeDecision(serial: "SN-2", units: 20, against: stored)
        #expect(decision == .duplicateBox)
    }

    @Test("Missing units are carried through so the user types the stock")
    func nilUnitsCarryThrough() {
        #expect(scanMergeDecision(serial: "SN-1", units: nil, against: nil) == .create(units: nil))
        let stored = StoredBoxState(recordedSerials: ["SN-9"])
        #expect(scanMergeDecision(serial: "SN-1", units: nil, against: stored) == .addStock(units: nil))
    }

    @Test("A box with no serial on an existing medication adds stock (cannot dedup)")
    func serialLessBoxAddsStock() {
        // EAN-13 OTC boxes carry no serial; without one, dedup is impossible → add stock.
        let stored = StoredBoxState(recordedSerials: ["SN-1"])
        #expect(scanMergeDecision(serial: nil, units: 20, against: stored) == .addStock(units: 20))
    }

    @Test("Merging expiry keeps the nearest of the stored and scanned dates")
    func mergedExpiryKeepsNearest() throws {
        let calendar = try utcCalendar()
        let stored = try isoDate("2028-03-31T00:00:00Z")
        let sooner = try isoDate("2027-10-31T00:00:00Z")
        let later = try isoDate("2029-01-31T00:00:00Z")

        let med = makeMedication(expiryDate: stored)
        // A sooner scanned box wins (the box that expires first governs the alert).
        #expect(med.mergedExpiry(with: sooner) == sooner)
        // A later scanned box leaves the stored (nearer) date untouched.
        #expect(med.mergedExpiry(with: later) == stored)
        _ = calendar
    }

    @Test("Merging expiry adopts the scanned date when none is stored, and keeps stored when none scanned")
    func mergedExpiryHandlesNil() throws {
        let scanned = try isoDate("2028-03-31T00:00:00Z")
        let withoutStored = makeMedication(expiryDate: nil)
        #expect(withoutStored.mergedExpiry(with: scanned) == scanned)

        let withStored = makeMedication(expiryDate: scanned)
        #expect(withStored.mergedExpiry(with: nil) == scanned)

        #expect(makeMedication(expiryDate: nil).mergedExpiry(with: nil) == nil)
    }
}
