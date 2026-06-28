//
//  CalendarTodayBoundsTests.swift
//  MedicAppRemindTests
//
//  v1.2 — TodayView's day window must track the wall clock so it rolls over at midnight.
//  These pin the pure helpers that compute the day's bounds and the delay to the next day.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Calendar today bounds")
struct CalendarTodayBoundsTests {

    /// A fixed Gregorian calendar in a known zone so the boundaries are deterministic.
    private static func madridCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        return calendar
    }

    @Test("dayBounds returns midnight-to-midnight for the date's day")
    func dayBoundsAreMidnightToMidnight() throws {
        let calendar = try Self.madridCalendar()
        let noon = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 28, hour: 12, minute: 30))
        )
        let bounds = calendar.dayBounds(for: noon)

        let expectedStart = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 28, hour: 0))
        )
        let expectedEnd = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 29, hour: 0))
        )
        #expect(bounds.start == expectedStart)
        #expect(bounds.end == expectedEnd)
    }

    @Test("secondsUntilNextDay counts the remaining seconds of the day")
    func secondsUntilNextDayCountsRemainder() throws {
        let calendar = try Self.madridCalendar()
        // 23:00 → exactly one hour (3600 s) to midnight.
        let elevenPM = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 28, hour: 23, minute: 0))
        )
        #expect(calendar.secondsUntilNextDay(after: elevenPM) == 3600)
    }

    @Test("secondsUntilNextDay at the day start counts a full day, never zero")
    func secondsUntilNextDayAtDayStartIsFullDay() throws {
        let calendar = try Self.madridCalendar()
        let midnight = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 6, day: 28, hour: 0))
        )
        // Exactly at the day start the whole day remains; the clamp guards against 0.
        #expect(calendar.secondsUntilNextDay(after: midnight) == 86_400)
    }
}
