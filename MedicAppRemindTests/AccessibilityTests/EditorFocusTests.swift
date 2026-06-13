//
//  EditorFocusTests.swift
//  MedicAppRemindTests
//
//  F6.S3 — Smoke tests for `EditorField.firstInvalidField(for:)`.
//  Verifies the priority mapping from a set of ValidationErrors to the
//  EditorField that should receive VoiceOver focus. Pure function: no UI, no store.
//

import Testing
@testable import MedicAppRemind

@Suite("EditorField.firstInvalidField")
struct EditorFocusTests {

    @Test("Empty error set returns nil — no focus movement needed")
    func noErrors() {
        #expect(EditorField.firstInvalidField(for: []) == nil)
    }

    @Test("emptyName alone → .name")
    func emptyNameAlone() {
        #expect(EditorField.firstInvalidField(for: [.emptyName]) == .name)
    }

    @Test("nonPositivePillsPerDose alone → .pillsPerDose")
    func pillsPerDoseAlone() {
        #expect(EditorField.firstInvalidField(for: [.nonPositivePillsPerDose]) == .pillsPerDose)
    }

    @Test("negativeStock alone → .stock")
    func negativeStockAlone() {
        #expect(EditorField.firstInvalidField(for: [.negativeStock]) == .stock)
    }

    @Test("emptySchedule alone → .schedule")
    func emptyScheduleAlone() {
        #expect(EditorField.firstInvalidField(for: [.emptySchedule]) == .schedule)
    }

    @Test("name error takes priority over all others")
    func namePriority() {
        let all: Set<ValidationError> = [
            .emptyName, .nonPositivePillsPerDose, .negativeStock, .emptySchedule
        ]
        #expect(EditorField.firstInvalidField(for: all) == .name)
    }

    @Test("pillsPerDose wins over stock and schedule when name is valid")
    func pillsPerDosePriority() {
        let errors: Set<ValidationError> = [.nonPositivePillsPerDose, .negativeStock, .emptySchedule]
        #expect(EditorField.firstInvalidField(for: errors) == .pillsPerDose)
    }

    @Test("stock wins over schedule when name and pillsPerDose are valid")
    func stockPriority() {
        let errors: Set<ValidationError> = [.negativeStock, .emptySchedule]
        #expect(EditorField.firstInvalidField(for: errors) == .stock)
    }
}
