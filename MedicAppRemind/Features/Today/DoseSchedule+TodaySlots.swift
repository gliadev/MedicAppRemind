//
//  DoseSchedule+TodaySlots.swift
//  MedicAppRemind
//
//  F6.S1 — Determines whether a schedule fires on a specific calendar date
//  and, if so, the concrete fire times for that day. Feeds TodayView's
//  dose-slot computation. Pure Foundation; no SwiftUI or SwiftData.
//

import Foundation

extension DoseSchedule {
    /// Whether this schedule is active on `date`.
    ///
    /// A schedule is active when:
    /// - `date` is on or after `startDate` (calendar-day granularity).
    /// - `date` is on or before `endDate` when one is set.
    /// - For `.weekdays` schedules: the calendar weekday of `date` is listed.
    func isActive(on date: Date, calendar: Calendar = .current) -> Bool {
        let targetDay = calendar.startOfDay(for: date)
        guard targetDay >= calendar.startOfDay(for: startDate) else { return false }
        if let endDate {
            guard targetDay <= calendar.startOfDay(for: endDate) else { return false }
        }
        if case .weekdays(let days) = frequency {
            let weekday = calendar.component(.weekday, from: date)
            return days.contains { $0.rawValue == weekday }
        }
        return true
    }

    /// The `Date` instances at which this schedule fires on `date`.
    ///
    /// Delegates to `doseTriggerComponents` for the hour/minute pattern, then
    /// stamps those times onto the calendar date given. `isActive` handles the
    /// weekday filter so callers get a clean list of concrete instants without
    /// any weekday component in the returned dates.
    ///
    /// Returns an empty array when the schedule is inactive on `date`.
    func fireTimes(on date: Date, calendar: Calendar = .current) -> [Date] {
        guard isActive(on: date, calendar: calendar) else { return [] }
        let dayBase = calendar.dateComponents([.year, .month, .day], from: date)
        return doseTriggerComponents(calendar: calendar).compactMap { component in
            var dc = dayBase
            dc.hour = component.hour
            dc.minute = component.minute
            return calendar.date(from: dc)
        }
    }
}
