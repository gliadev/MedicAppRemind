//
//  MedicationDraftTests.swift
//  MedicAppRemindTests
//
//  F10.S1 — The quick-add draft prefills the editor with only what the text
//  carried: absent fields stay untouched, invalid values are dropped (never
//  corrected), and the editor's own validation remains the single save gate.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("MedicationDraft → editor prefill")
struct MedicationDraftTests {

    // MARK: - Complete draft

    @Test("A complete draft prefills every field with hand-checked values")
    func completeDraftPrefillsEverything() throws {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            doseLabel: "600 mg",
            pillsPerDose: 1,
            form: .tablet,
            currentStock: 30,
            schedule: DraftSchedule(timesOfDay: [DraftTime(hour: 8, minute: 0)], kind: .everyNHours(8)),
            sourceText: "Ibuprofeno 600, una cada 8 horas, tengo 30"
        )

        let prefill = draft.editorPrefill()
        #expect(prefill.name == "Ibuprofeno")
        #expect(prefill.doseLabel == "600 mg")
        #expect(prefill.pillsPerDose == 1.0)
        #expect(prefill.form == .tablet)
        #expect(prefill.currentStock == 30.0)

        let schedule = try #require(prefill.schedule)
        #expect(schedule.frequency == .everyNHours(8))
        #expect(schedule.times == [DateComponents(hour: 8, minute: 0)])
    }

    // MARK: - Partial draft

    @Test("A name-only draft prefills only the name")
    func nameOnlyDraftPrefillsOnlyName() {
        let draft = MedicationDraft(name: "Paracetamol", sourceText: "paracetamol y ya está")

        let prefill = draft.editorPrefill()
        #expect(prefill.name == "Paracetamol")
        #expect(prefill.doseLabel == nil)
        #expect(prefill.pillsPerDose == nil)
        #expect(prefill.form == nil)
        #expect(prefill.currentStock == nil)
        #expect(prefill.schedule == nil)
    }

    @Test("Name and dose label are trimmed; whitespace-only becomes nil")
    func textFieldsTrimmedOrDropped() {
        let draft = MedicationDraft(
            name: "  Paracetamol ",
            doseLabel: "   ",
            sourceText: "paracetamol"
        )

        let prefill = draft.editorPrefill()
        #expect(prefill.name == "Paracetamol")
        #expect(prefill.doseLabel == nil)
    }

    // MARK: - Defensive clamps: drop, never correct

    @Test("Negative stock and non-positive pills per dose are dropped; the draft stays usable")
    func invalidNumbersDropped() {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            pillsPerDose: 0,
            currentStock: -5,
            sourceText: "ibuprofeno, stock raro"
        )

        let prefill = draft.editorPrefill()
        #expect(prefill.name == "Ibuprofeno")
        #expect(prefill.pillsPerDose == nil)
        #expect(prefill.currentStock == nil)
    }

    @Test("Absurd or non-finite magnitudes are dropped")
    func absurdNumbersDropped() {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            pillsPerDose: 999,
            currentStock: 50_000,
            sourceText: "ibuprofeno"
        )

        let prefill = draft.editorPrefill()
        #expect(prefill.pillsPerDose == nil)
        #expect(prefill.currentStock == nil)

        let nanDraft = MedicationDraft(
            name: "Ibuprofeno",
            pillsPerDose: .nan,
            currentStock: .infinity,
            sourceText: "ibuprofeno"
        )
        #expect(nanDraft.editorPrefill().pillsPerDose == nil)
        #expect(nanDraft.editorPrefill().currentStock == nil)
    }

    @Test("Fractional doses within clinical range survive (half a pill)")
    func fractionalDoseSurvives() {
        let draft = MedicationDraft(
            name: "Sintrom",
            pillsPerDose: 0.5,
            sourceText: "medio comprimido de sintrom"
        )
        #expect(draft.editorPrefill().pillsPerDose == 0.5)
    }

    // MARK: - Schedule

    @Test("An empty drafted schedule prefills no schedule — the editor still demands a pauta to save")
    func emptyScheduleIsNilInPrefill() {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            schedule: DraftSchedule(timesOfDay: nil, kind: .daily),
            sourceText: "ibuprofeno sin pauta"
        )
        #expect(draft.editorPrefill().schedule == nil)
    }

    // MARK: - Last gate stays with the existing validation

    @Test("A prefilled medication still passes through Medication.validated() unchanged")
    func prefillFeedsExistingValidation() throws {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            pillsPerDose: 1,
            currentStock: 30,
            sourceText: "ibuprofeno"
        )
        let prefill = draft.editorPrefill()

        let medication = makeMedication(
            name: prefill.name ?? "",
            pillsPerDose: prefill.pillsPerDose ?? 1,
            currentStock: prefill.currentStock ?? 0
        )
        #expect(try medication.validated() == medication)
    }
}
