//
//  Calendar+TodayBounds.swift
//  MedicAppRemind
//
//  v1.2 — TodayView's @Query window and "today" reference must follow the wall clock.
//  Previously both were frozen at `init()`, so a view alive across midnight kept showing
//  the previous day. These pure helpers give the day's half-open bounds (for the query
//  predicate) and the delay until the next day starts (to schedule a midnight refresh).
//

import Foundation

extension Calendar {
    /// The half-open interval `[startOfDay, startOfNextDay)` covering `date`'s calendar day.
    ///
    /// Used to bound the day's intake-log query. Half-open so a dose at exactly 00:00 of the
    /// next day belongs to that day, never double-counted.
    func dayBounds(for date: Date) -> (start: Date, end: Date) {
        let start = startOfDay(for: date)
        let end = self.date(byAdding: .day, value: 1, to: start) ?? start
        return (start, end)
    }

    /// Seconds from `date` until the start of the next calendar day.
    ///
    /// Drives the midnight refresh timer. Clamped to at least 1 second so a call made
    /// exactly at midnight schedules the *following* day instead of spinning on 0.
    func secondsUntilNextDay(after date: Date) -> TimeInterval {
        let start = startOfDay(for: date)
        let next = self.date(byAdding: .day, value: 1, to: start) ?? date
        return max(1, next.timeIntervalSince(date))
    }
}
