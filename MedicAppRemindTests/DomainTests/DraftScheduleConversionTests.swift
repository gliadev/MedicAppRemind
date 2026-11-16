//
//  DraftScheduleConversionTests.swift
//  MedicAppRemindTests
//
//  F10.S1 — The drafted schedule (flat, LLM-generable mirror) must convert to
//  the Domain's DoseFrequency/DateComponents deterministically. Invalid values
//  are dropped, never silently corrected; a schedule that could never fire
//  converts to nil so the editor asks for a pauta, exactly as it does today.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("DraftSchedule → editor prefill conversion")
struct DraftScheduleConversionTests {

    // MARK: - Frequency mapping

    @Test("everyNHours(8) maps to DoseFrequency.everyNHours(8) with its anchor, three doses a day")
    func everyEightHoursMapsAndAnchors() throws {
        let draft = DraftSchedule(timesOfDay: [DraftTime(hour: 8, minute: 0)], kind: .everyNHours(8))
        let prefill = try #require(draft.editorPrefill())
        #expect(prefill.frequency == .everyNHours(8))
        #expect(prefill.times == [DateComponents(hour: 8, minute: 0)])

        // 24 h / 8 h = 3 tomas — reuses the Domain's dose math as the oracle.
        let schedule = makeSchedule(prefill.frequency, times: prefill.times)
        #expect(schedule.dosesPerDay == 3)
    }

    @Test("Weekdays round-trip sorted and deduplicated")
    func weekdaysRoundTrip() throws {
        let draft = DraftSchedule(
            timesOfDay: [DraftTime(hour: 9, minute: 15)],
            kind: .weekdays([.friday, .monday, .monday])
        )
        let prefill = try #require(draft.editorPrefill())
        #expect(prefill.frequency == .weekdays([.monday, .friday]))
        #expect(prefill.times == [DateComponents(hour: 9, minute: 15)])
    }

    @Test("timesOfDay map to exact hour/minute components, in order")
    func timesMapExactly() throws {
        let draft = DraftSchedule(
            timesOfDay: [DraftTime(hour: 8, minute: 0), DraftTime(hour: 16, minute: 30)],
            kind: .daily
        )
        let prefill = try #require(draft.editorPrefill())
        #expect(prefill.frequency == .daily)
        #expect(prefill.times == [DateComponents(hour: 8, minute: 0), DateComponents(hour: 16, minute: 30)])
    }

    // MARK: - Invalid values are dropped, never corrected

    @Test("An out-of-range time is dropped; the valid ones survive")
    func invalidTimeDropped() throws {
        let draft = DraftSchedule(
            timesOfDay: [
                DraftTime(hour: 25, minute: 0),
                DraftTime(hour: 9, minute: 15),
                DraftTime(hour: 9, minute: 75)
            ],
            kind: .daily
        )
        let prefill = try #require(draft.editorPrefill())
        #expect(prefill.times == [DateComponents(hour: 9, minute: 15)])
    }

    @Test("A daily schedule whose only time is invalid never fires → nil")
    func dailyWithOnlyInvalidTimeIsNil() {
        let draft = DraftSchedule(timesOfDay: [DraftTime(hour: 24, minute: 0)], kind: .daily)
        #expect(draft.editorPrefill() == nil)
    }

    @Test("Empty or absent timesOfDay with a per-day kind → nil")
    func emptyScheduleIsNil() {
        #expect(DraftSchedule(timesOfDay: nil, kind: .daily).editorPrefill() == nil)
        #expect(DraftSchedule(timesOfDay: [], kind: .daily).editorPrefill() == nil)
    }

    @Test("A weekday schedule without any weekday → nil")
    func emptyWeekdaysIsNil() {
        let draft = DraftSchedule(timesOfDay: [DraftTime(hour: 8, minute: 0)], kind: .weekdays([]))
        #expect(draft.editorPrefill() == nil)
    }

    @Test("An interval outside 1...24 hours → nil")
    func absurdIntervalIsNil() {
        #expect(DraftSchedule(timesOfDay: nil, kind: .everyNHours(0)).editorPrefill() == nil)
        #expect(DraftSchedule(timesOfDay: nil, kind: .everyNHours(48)).editorPrefill() == nil)
    }

    @Test("An interval schedule needs no times; the editor keeps its default anchor")
    func intervalWithoutTimesIsValid() throws {
        let prefill = try #require(DraftSchedule(timesOfDay: nil, kind: .everyNHours(12)).editorPrefill())
        #expect(prefill.frequency == .everyNHours(12))
        #expect(prefill.times.isEmpty)
    }
}
