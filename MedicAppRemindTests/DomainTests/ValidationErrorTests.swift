//
//  ValidationErrorTests.swift
//  MedicAppRemindTests
//
//  F1.S3 — Domain validation. Each test asserts the exact error case,
//  never the broad `Error.self`.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ValidationError")
struct ValidationErrorTests {

    // MARK: - Medication.validated()

    @Test("An empty name throws .emptyName")
    func emptyNameThrows() {
        #expect(throws: ValidationError.emptyName) {
            try makeMedication(name: "").validated()
        }
    }

    @Test("A whitespace-only name throws .emptyName")
    func whitespaceOnlyNameThrows() {
        #expect(throws: ValidationError.emptyName) {
            try makeMedication(name: "   ").validated()
        }
    }

    @Test("Negative stock throws .negativeStock")
    func negativeStockThrows() {
        #expect(throws: ValidationError.negativeStock) {
            try makeMedication(currentStock: -1).validated()
        }
    }

    @Test("Zero pills per dose throws .nonPositivePillsPerDose")
    func zeroPillsPerDoseThrows() {
        #expect(throws: ValidationError.nonPositivePillsPerDose) {
            try makeMedication(pillsPerDose: 0).validated()
        }
    }

    @Test("Negative pills per dose throws .nonPositivePillsPerDose")
    func negativePillsPerDoseThrows() {
        #expect(throws: ValidationError.nonPositivePillsPerDose) {
            try makeMedication(pillsPerDose: -2).validated()
        }
    }

    @Test("A valid medication does not throw")
    func validMedicationDoesNotThrow() {
        #expect(throws: Never.self) {
            try makeMedication().validated()
        }
    }

    // MARK: - DoseSchedule.validated()

    @Test("A schedule that never fires throws .emptySchedule")
    func emptyScheduleThrows() {
        #expect(throws: ValidationError.emptySchedule) {
            try makeSchedule(.daily, times: []).validated()
        }
    }

    @Test("A schedule with a dose time does not throw")
    func nonEmptyScheduleDoesNotThrow() {
        #expect(throws: Never.self) {
            try makeSchedule(.daily, times: [DateComponents(hour: 9)]).validated()
        }
    }

    // MARK: - Localized descriptions

    @Test("Every error case has a non-empty localized description")
    func everyCaseHasLocalizedDescription() {
        let cases: [ValidationError] = [.emptyName, .negativeStock, .nonPositivePillsPerDose, .emptySchedule]
        for error in cases {
            #expect(error.errorDescription?.isEmpty == false)
        }
    }
}
