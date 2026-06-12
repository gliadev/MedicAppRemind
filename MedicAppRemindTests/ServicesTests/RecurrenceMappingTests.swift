//
//  RecurrenceMappingTests.swift
//  MedicAppRemindTests
//
//  F4.S1 — The pure decision behind calendar integration. The mapping from a dose
//  frequency to a recurrence, and from a schedule to its event seeds, is tested here;
//  the EventKit effect (EKEventStore) is never touched. Every test fixes an input and
//  asserts a hand-computed output.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("RecurrenceMapping")
struct RecurrenceMappingTests {

    // MARK: - DoseFrequency → DoseRecurrence

    @Test("Daily maps to a daily recurrence, interval 1, no weekdays")
    func dailyMapsToDaily() {
        #expect(DoseFrequency.daily.recurrence == DoseRecurrence(cadence: .daily, interval: 1, weekdays: []))
    }

    @Test("Every-N-hours maps to a daily recurrence — the multiplicity comes from the event seeds")
    func everyNHoursMapsToDaily() {
        #expect(DoseFrequency.everyNHours(8).recurrence == DoseRecurrence(cadence: .daily, interval: 1, weekdays: []))
    }

    @Test("Weekdays maps to a weekly recurrence carrying exactly those days")
    func weekdaysMapsToWeekly() {
        let recurrence = DoseFrequency.weekdays([.monday, .friday]).recurrence
        #expect(recurrence == DoseRecurrence(cadence: .weekly, interval: 1, weekdays: [.monday, .friday]))
    }

    @Test("A frequency that never recurs maps to nil")
    func nonRecurringMapsToNil() {
        #expect(DoseFrequency.weekdays([]).recurrence == nil)
        #expect(DoseFrequency.everyNHours(0).recurrence == nil)
        #expect(DoseFrequency.everyNHours(-3).recurrence == nil)
    }

    // MARK: - DoseSchedule → calendar event seeds

    @Test("A daily schedule seeds one event per time of day")
    func dailySeedsOnePerTime() throws {
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 9), DateComponents(hour: 21, minute: 30)])
        #expect(schedule.calendarEventSeeds(calendar: try utcCalendar()) == [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 21, minute: 30),
        ])
    }

    @Test("Every-8h from an 08:00 start seeds three daily-anchored events")
    func everyEightHoursSeedsThree() throws {
        let schedule = makeSchedule(.everyNHours(8), startDate: try isoDate("2026-06-09T08:00:00Z"))
        #expect(schedule.calendarEventSeeds(calendar: try utcCalendar()) == [
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 16, minute: 0),
            DateComponents(hour: 0, minute: 0),
        ])
    }

    @Test("A weekly schedule seeds one event per time, anchored to the earliest weekday")
    func weeklySeedsAnchoredToEarliestWeekday() throws {
        let schedule = makeSchedule(.weekdays([.friday, .monday]), times: [DateComponents(hour: 9)])
        // Monday = 2 is the earliest Calendar weekday; the recurrence rule then emits Friday.
        #expect(schedule.calendarEventSeeds(calendar: try utcCalendar()) == [
            DateComponents(hour: 9, minute: 0, weekday: 2),
        ])
    }

    @Test("A weekly schedule with no active days seeds nothing")
    func weeklyWithNoDaysSeedsNothing() throws {
        let schedule = makeSchedule(.weekdays([]), times: [DateComponents(hour: 9)])
        #expect(schedule.calendarEventSeeds(calendar: try utcCalendar()).isEmpty)
    }
}
