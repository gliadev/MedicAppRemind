//
//  DoseFrequency+Recurrence.swift
//  MedicAppRemind
//
//  F4.S1 — Pure decision: maps the dosing rhythm to a single event's recurrence.
//  No EventKit import — this stays pure and is the unit under test.
//

import Foundation

extension DoseFrequency {
    /// The recurrence for one calendar event representing this frequency.
    ///
    /// - `.daily`: repeats every day.
    /// - `.everyNHours`: each per-dose event repeats **daily** — the several-times-a-day
    ///   rhythm is expressed by creating one event per anchor time
    ///   (`DoseSchedule.calendarEventSeeds`), not by the rule. So the rule is daily.
    /// - `.weekdays(days)`: repeats weekly on exactly those days.
    ///
    /// Returns `nil` when the schedule never recurs (`.weekdays([])`, `.everyNHours(≤0)`),
    /// so the caller creates no event.
    var recurrence: DoseRecurrence? {
        switch self {
        case .daily:
            return DoseRecurrence(cadence: .daily, interval: 1, weekdays: [])
        case .everyNHours(let hours):
            guard hours > 0 else { return nil }
            return DoseRecurrence(cadence: .daily, interval: 1, weekdays: [])
        case .weekdays(let days):
            guard !days.isEmpty else { return nil }
            return DoseRecurrence(cadence: .weekly, interval: 1, weekdays: days)
        }
    }
}
