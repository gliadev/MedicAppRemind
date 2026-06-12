//
//  DoseSchedule+CalendarEvents.swift
//  MedicAppRemind
//
//  F4.S1 — Pure decision: the time-of-day anchors for which CalendarService creates one
//  recurring event each. Keeping this out of the effect means the per-frequency branching
//  is unit-tested rather than buried in the EventKit save loop.
//

import Foundation

extension DoseSchedule {
    /// One time-of-day per recurring calendar event to create.
    ///
    /// - `.daily` / `.everyNHours`: each dose trigger (see `doseTriggerComponents`) becomes
    ///   its own daily-repeating event — so an "every 8h" plan seeds three events.
    /// - `.weekdays`: the weekday set lives in the recurrence rule, so the seeds are just the
    ///   times of day, each anchored to the **earliest** listed weekday (the rule then emits
    ///   the rest). Returns `[]` when no weekday is active.
    ///
    /// - Parameter calendar: forwarded to `doseTriggerComponents` to read the start time of
    ///   day for every-N-hours plans; injectable for tests.
    func calendarEventSeeds(calendar: Calendar = .current) -> [DateComponents] {
        switch frequency {
        case .daily, .everyNHours:
            return doseTriggerComponents(calendar: calendar)
        case .weekdays(let days):
            guard let firstWeekday = days.map(\.rawValue).min() else { return [] }
            return times.map { time in
                DateComponents(hour: time.hour ?? 0, minute: time.minute ?? 0, weekday: firstWeekday)
            }
        }
    }
}
