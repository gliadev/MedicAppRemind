//
//  DoseReminderPlanningTests.swift
//  MedicAppRemindTests
//
//  F3.S1 — Pure dose-reminder planning. The decision (which trigger components,
//  which identifiers) is tested here; the effect (UNUserNotificationCenter) is not.
//  Every test fixes an input and asserts a hand-computed output. Dates are injected.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("DoseReminderPlanning")
struct DoseReminderPlanningTests {

    /// Gregorian calendar pinned to UTC so a fixture's start time-of-day is
    /// extracted deterministically, independent of the test machine's zone.
    private func utcCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        return calendar
    }

    private func startDate(_ iso: String) throws -> Date {
        try Date(iso, strategy: .iso8601)
    }

    // MARK: - everyNHours: anchored at the schedule's start time of day

    @Test("Every 8h from an 08:00 start fires at 08:00, 16:00, 00:00")
    func everyEightHoursAnchorsAtStartTime() throws {
        let schedule = makeSchedule(.everyNHours(8), startDate: try startDate("2026-06-09T08:00:00Z"))
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        #expect(components == [
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 16, minute: 0),
            DateComponents(hour: 0, minute: 0),
        ])
    }

    @Test("Every 8h from 22:30 wraps past midnight and preserves the minute")
    func everyEightHoursWrapsAndKeepsMinute() throws {
        let schedule = makeSchedule(.everyNHours(8), startDate: try startDate("2026-06-09T22:30:00Z"))
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        // 22:30 → +8h 06:30 (next day) → +8h 14:30.
        #expect(components == [
            DateComponents(hour: 22, minute: 30),
            DateComponents(hour: 6, minute: 30),
            DateComponents(hour: 14, minute: 30),
        ])
    }

    @Test("Every 6h from midnight fires four times a day")
    func everySixHoursFromMidnight() throws {
        let schedule = makeSchedule(.everyNHours(6), startDate: try startDate("2026-06-09T00:00:00Z"))
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        #expect(components == [
            DateComponents(hour: 0, minute: 0),
            DateComponents(hour: 6, minute: 0),
            DateComponents(hour: 12, minute: 0),
            DateComponents(hour: 18, minute: 0),
        ])
    }

    @Test("An interval that does not divide 24 ceils to cover the whole day")
    func everyFiveHoursCeilsToFiveTriggers() throws {
        // 24/5 = 4.8 → 5 triggers; the last gap before the next day's anchor is short.
        let schedule = makeSchedule(.everyNHours(5), startDate: try startDate("2026-06-09T08:00:00Z"))
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        #expect(components == [
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 13, minute: 0),
            DateComponents(hour: 18, minute: 0),
            DateComponents(hour: 23, minute: 0),
            DateComponents(hour: 4, minute: 0),
        ])
    }

    @Test("Every-N-hours ignores times of day and anchors only on the start date")
    func everyNHoursIgnoresTimes() throws {
        let schedule = makeSchedule(.everyNHours(8), times: [], startDate: try startDate("2026-06-09T08:00:00Z"))
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        #expect(components == [
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 16, minute: 0),
            DateComponents(hour: 0, minute: 0),
        ])
    }

    @Test("A non-positive interval produces no triggers")
    func nonPositiveIntervalProducesNoTriggers() throws {
        #expect(makeSchedule(.everyNHours(0)).doseTriggerComponents(calendar: try utcCalendar()).isEmpty)
        #expect(makeSchedule(.everyNHours(-3)).doseTriggerComponents(calendar: try utcCalendar()).isEmpty)
    }

    // MARK: - daily

    @Test("A daily schedule yields one component per time of day")
    func dailyYieldsOneComponentPerTime() throws {
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 9), DateComponents(hour: 21, minute: 30)])
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        #expect(components == [
            DateComponents(hour: 9, minute: 0),
            DateComponents(hour: 21, minute: 30),
        ])
    }

    @Test("A daily schedule with no times yields no triggers")
    func dailyWithNoTimesYieldsNothing() throws {
        #expect(makeSchedule(.daily, times: []).doseTriggerComponents(calendar: try utcCalendar()).isEmpty)
    }

    // MARK: - weekdays

    @Test("Weekdays expands to one component per (day × time)")
    func weekdaysExpandsDayByTime() throws {
        let schedule = makeSchedule(
            .weekdays([.monday, .wednesday]),
            times: [DateComponents(hour: 9), DateComponents(hour: 21)]
        )
        let components = schedule.doseTriggerComponents(calendar: try utcCalendar())
        // Monday = 2, Wednesday = 4 (Calendar Gregorian weekday); day-major order.
        #expect(components == [
            DateComponents(hour: 9, minute: 0, weekday: 2),
            DateComponents(hour: 21, minute: 0, weekday: 2),
            DateComponents(hour: 9, minute: 0, weekday: 4),
            DateComponents(hour: 21, minute: 0, weekday: 4),
        ])
    }

    @Test("Weekdays with no active days yields no triggers")
    func weekdaysWithNoDaysYieldsNothing() throws {
        #expect(makeSchedule(.weekdays([])).doseTriggerComponents(calendar: try utcCalendar()).isEmpty)
    }

    // MARK: - identifiers

    @Test("The same medication and component always yield the same identifier")
    func identifierIsDeterministic() {
        let med = makeMedication()
        let component = DateComponents(hour: 8, minute: 0)
        #expect(med.doseIdentifier(for: component) == med.doseIdentifier(for: component))
    }

    @Test("Distinct trigger components of one medication get distinct identifiers")
    func identifiersAreUniquePerComponent() throws {
        let med = makeMedication()
        let schedule = makeSchedule(.everyNHours(8), startDate: try startDate("2026-06-09T08:00:00Z"))
        let identifiers = schedule.doseTriggerComponents(calendar: try utcCalendar())
            .map { med.doseIdentifier(for: $0) }
        #expect(Set(identifiers).count == identifiers.count)
        #expect(identifiers.count == 3)
    }

    @Test("The weekday distinguishes identifiers that share an hour and minute")
    func weekdayDistinguishesIdentifiers() {
        let med = makeMedication()
        let monday = DateComponents(hour: 9, minute: 0, weekday: 2)
        let wednesday = DateComponents(hour: 9, minute: 0, weekday: 4)
        #expect(med.doseIdentifier(for: monday) != med.doseIdentifier(for: wednesday))
    }

    @Test("Every dose identifier carries the medication's cancellation prefix")
    func identifierCarriesCancellationPrefix() {
        let med = makeMedication()
        let identifier = med.doseIdentifier(for: DateComponents(hour: 8, minute: 0))
        #expect(identifier.hasPrefix(med.doseIdentifierPrefix))
    }
}
