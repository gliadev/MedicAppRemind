//
//  GeneratedDraftMappingTests.swift
//  MedicAppRemindTests
//
//  F10.S2 — The @Generable mirror must map field-by-field onto the Domain
//  draft without inventing anything: nil stays nil, and a frequency that
//  cannot be built (interval kind without an interval) maps to no schedule.
//  These are plain structs — no model run is ever involved.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("GeneratedMedicationDraft → MedicationDraft mapping")
struct GeneratedDraftMappingTests {

    @Test("A fully populated generated draft maps field by field")
    func fullMapping() throws {
        let generated = GeneratedMedicationDraft(
            name: "Ibuprofeno",
            doseLabel: "600 mg",
            pillsPerDose: 1,
            form: .tablet,
            currentStock: 30,
            schedule: GeneratedSchedule(
                timesOfDay: [GeneratedTime(hour: 8, minute: 0)],
                kind: .everyNHours,
                intervalHours: 8,
                weekdays: nil
            )
        )

        let draft = generated.toDomainDraft(sourceText: "Ibuprofeno 600, una cada 8 horas, tengo 30")
        #expect(draft.name == "Ibuprofeno")
        #expect(draft.doseLabel == "600 mg")
        #expect(draft.pillsPerDose == 1.0)
        #expect(draft.form == .tablet)
        #expect(draft.currentStock == 30.0)
        #expect(draft.sourceText == "Ibuprofeno 600, una cada 8 horas, tengo 30")

        let schedule = try #require(draft.schedule)
        #expect(schedule.kind == .everyNHours(8))
        #expect(schedule.timesOfDay == [DraftTime(hour: 8, minute: 0)])
    }

    @Test("An empty generated draft carries only the source text")
    func allNilsRespected() {
        let generated = GeneratedMedicationDraft(
            name: nil,
            doseLabel: nil,
            pillsPerDose: nil,
            form: nil,
            currentStock: nil,
            schedule: nil
        )

        let draft = generated.toDomainDraft(sourceText: "paracetamol y ya está")
        #expect(draft.name == nil)
        #expect(draft.doseLabel == nil)
        #expect(draft.pillsPerDose == nil)
        #expect(draft.form == nil)
        #expect(draft.currentStock == nil)
        #expect(draft.schedule == nil)
        #expect(draft.sourceText == "paracetamol y ya está")
    }

    @Test("Weekday kind maps the listed days in order")
    func weekdaysMapping() throws {
        let generated = GeneratedSchedule(
            timesOfDay: [GeneratedTime(hour: 9, minute: 30)],
            kind: .weekdays,
            intervalHours: nil,
            weekdays: [.monday, .friday]
        )

        let schedule = try #require(generated.toDomainSchedule())
        #expect(schedule.kind == .weekdays([.monday, .friday]))
        #expect(schedule.timesOfDay == [DraftTime(hour: 9, minute: 30)])
    }

    @Test("Daily kind maps without needing interval or weekdays")
    func dailyMapping() throws {
        let generated = GeneratedSchedule(
            timesOfDay: [GeneratedTime(hour: 8, minute: 0), GeneratedTime(hour: 21, minute: 0)],
            kind: .daily,
            intervalHours: nil,
            weekdays: nil
        )

        let schedule = try #require(generated.toDomainSchedule())
        #expect(schedule.kind == .daily)
        #expect(schedule.timesOfDay == [DraftTime(hour: 8, minute: 0), DraftTime(hour: 21, minute: 0)])
    }

    @Test("Interval kind without an interval value maps to no schedule — never invented")
    func intervalWithoutValueIsNil() {
        let generated = GeneratedSchedule(
            timesOfDay: [GeneratedTime(hour: 8, minute: 0)],
            kind: .everyNHours,
            intervalHours: nil,
            weekdays: nil
        )
        #expect(generated.toDomainSchedule() == nil)
    }

    @Test("Weekday kind with no days maps to an empty weekday list (S1 conversion drops it)")
    func weekdaysWithoutDaysMapsEmpty() throws {
        let generated = GeneratedSchedule(
            timesOfDay: [GeneratedTime(hour: 8, minute: 0)],
            kind: .weekdays,
            intervalHours: nil,
            weekdays: nil
        )
        let schedule = try #require(generated.toDomainSchedule())
        #expect(schedule.kind == .weekdays([]))
    }

    @Test("Every generated form maps onto its Domain counterpart")
    func formMapping() {
        #expect(GeneratedMedicationForm.pill.toDomainForm() == .pill)
        #expect(GeneratedMedicationForm.capsule.toDomainForm() == .capsule)
        #expect(GeneratedMedicationForm.tablet.toDomainForm() == .tablet)
        #expect(GeneratedMedicationForm.liquid.toDomainForm() == .liquid)
        #expect(GeneratedMedicationForm.injection.toDomainForm() == .injection)
        #expect(GeneratedMedicationForm.other.toDomainForm() == .other)
    }
}
