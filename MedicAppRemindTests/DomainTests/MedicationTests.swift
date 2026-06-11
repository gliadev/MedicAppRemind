//
//  MedicationTests.swift
//  MedicAppRemindTests
//
//  F1.S1 — Value semantics and Codable round-trip for `Medication`.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Medication")
struct MedicationTests {

    @Test("Encoding then decoding reproduces an equal medication")
    func codableRoundTripPreservesValue() throws {
        let original = makeMedication(notes: "Con las comidas", currentStock: 42)
        let decoded = try roundTripJSON(original)
        #expect(decoded == original)
    }

    @Test("Medications with identical field values are equal")
    func sameValuesCompareEqual() {
        let a = makeMedication(name: "Paracetamol", currentStock: 20)
        let b = makeMedication(name: "Paracetamol", currentStock: 20)
        #expect(a == b)
    }

    @Test("A single differing field breaks equality")
    func differingStockBreaksEquality() {
        let a = makeMedication(currentStock: 30)
        let b = makeMedication(currentStock: 29)
        #expect(a != b)
    }

    @Test("The medication form survives a Codable round-trip")
    func formRoundTrips() throws {
        let original = makeMedication(form: .injection)
        let decoded = try roundTripJSON(original)
        #expect(decoded.form == .injection)
    }
}
