//
//  ScheduleKindTests.swift
//  MedicAppRemindTests
//
//  AX-04 — The editor's form state must map to `DoseFrequency` and back without
//  drift, so a saved-then-reopened pauta shows exactly what was stored.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ScheduleKind ↔ DoseFrequency")
struct ScheduleKindTests {

    // MARK: - Form state → frequency

    @Test("Daily mode ignores days and interval")
    func dailyBuildsDaily() {
        let frequency = DoseFrequency(kind: .daily, weekdays: [.monday], intervalHours: 6)
        #expect(frequency == .daily)
    }

    @Test("Weekly mode stores the selected days sorted, regardless of tap order")
    func weekdaysSortedDeterministically() {
        let frequency = DoseFrequency(
            kind: .weekdays,
            weekdays: [.friday, .monday, .wednesday],
            intervalHours: 8
        )
        #expect(frequency == .weekdays([.monday, .wednesday, .friday]))
    }

    @Test("Interval mode stores the chosen interval")
    func everyNHoursStoresInterval() {
        let frequency = DoseFrequency(kind: .everyNHours, weekdays: [], intervalHours: 8)
        #expect(frequency == .everyNHours(8))
    }

    @Test("Empty weekday selection builds an empty weekly frequency")
    func emptyWeekdaysBuildsEmptyWeekly() {
        let frequency = DoseFrequency(kind: .weekdays, weekdays: [], intervalHours: 8)
        #expect(frequency == .weekdays([]))
    }

    // MARK: - Frequency → form state (editor seeding)

    @Test("ScheduleKind derives from an existing frequency")
    func kindDerivesFromFrequency() {
        #expect(ScheduleKind(.daily) == .daily)
        #expect(ScheduleKind(.weekdays([.tuesday])) == .weekdays)
        #expect(ScheduleKind(.everyNHours(12)) == .everyNHours)
    }

    @Test("selectedWeekdays exposes weekly days and is empty otherwise")
    func selectedWeekdaysExtraction() {
        #expect(DoseFrequency.weekdays([.monday, .thursday]).selectedWeekdays == [.monday, .thursday])
        #expect(DoseFrequency.daily.selectedWeekdays.isEmpty)
        #expect(DoseFrequency.everyNHours(8).selectedWeekdays.isEmpty)
    }

    @Test("intervalHours exposes the interval and is nil otherwise")
    func intervalHoursExtraction() {
        #expect(DoseFrequency.everyNHours(6).intervalHours == 6)
        #expect(DoseFrequency.daily.intervalHours == nil)
        #expect(DoseFrequency.weekdays([.monday]).intervalHours == nil)
    }

    // MARK: - Round-trip

    @Test("Frequency survives a state round-trip", arguments: [
        DoseFrequency.daily,
        DoseFrequency.weekdays([.monday, .wednesday, .friday]),
        DoseFrequency.everyNHours(8)
    ])
    func roundTripThroughFormState(_ original: DoseFrequency) {
        let kind = ScheduleKind(original)
        let rebuilt = DoseFrequency(
            kind: kind,
            weekdays: original.selectedWeekdays,
            intervalHours: original.intervalHours ?? DoseFrequency.defaultIntervalHours
        )
        #expect(rebuilt == original)
    }

    // MARK: - Connects to validation

    @Test("A weekly pauta with no days selected is rejected by validation")
    func emptyWeeklyFailsValidation() {
        let schedule = DoseSchedule(
            times: [DateComponents(hour: 8)],
            frequency: DoseFrequency(kind: .weekdays, weekdays: [], intervalHours: 8),
            startDate: .now,
            endDate: nil
        )
        #expect(throws: ValidationError.emptySchedule) {
            try schedule.validated()
        }
    }

    @Test("An interval pauta needs no times to be valid")
    func intervalNeedsNoTimes() throws {
        let schedule = DoseSchedule(
            times: [],
            frequency: DoseFrequency(kind: .everyNHours, weekdays: [], intervalHours: 8),
            startDate: .now,
            endDate: nil
        )
        let validated = try schedule.validated()
        #expect(validated.dosesPerDay == 3)
    }
}
