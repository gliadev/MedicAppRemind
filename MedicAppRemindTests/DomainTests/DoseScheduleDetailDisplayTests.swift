//
//  DoseScheduleDetailDisplayTests.swift
//  MedicAppRemindTests
//
//  v1.2 — The detail's schedule section must show the right times for every pauta kind:
//  daily and weekly list their stored times once; an interval pauta (no stored times)
//  must derive its fire times instead of rendering an empty section.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("DoseSchedule detail display times")
struct DoseScheduleDetailDisplayTests {

    @Test("Daily lists its times sorted within the day")
    func dailySortsTimes() {
        let schedule = DoseSchedule(
            times: [DateComponents(hour: 21), DateComponents(hour: 8, minute: 30)],
            frequency: .daily,
            startDate: .now,
            endDate: nil
        )
        #expect(schedule.displayDoseTimes() == [
            DateComponents(hour: 8, minute: 30),
            DateComponents(hour: 21, minute: 0)
        ])
    }

    @Test("Weekly lists each time once, not duplicated per selected day")
    func weeklyListsTimesOnce() {
        let schedule = DoseSchedule(
            times: [DateComponents(hour: 9)],
            frequency: .weekdays([.monday, .wednesday, .friday]),
            startDate: .now,
            endDate: nil
        )
        #expect(schedule.displayDoseTimes() == [DateComponents(hour: 9, minute: 0)])
    }

    @Test("Interval derives fire times from the start hour, ignoring the empty times")
    func intervalDerivesFireTimes() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        let startDate = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 28, hour: 8, minute: 0))
        )
        let schedule = DoseSchedule(
            times: [],
            frequency: .everyNHours(8),
            startDate: startDate,
            endDate: nil
        )
        // 08:00 every 8h → 08:00, 16:00, 00:00 → sorted within the day.
        #expect(schedule.displayDoseTimes(calendar: calendar) == [
            DateComponents(hour: 0, minute: 0),
            DateComponents(hour: 8, minute: 0),
            DateComponents(hour: 16, minute: 0)
        ])
    }
}
