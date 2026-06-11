//
//  DoseSchedule+DoseTriggers.swift
//  MedicAppRemind
//
//  F3.S1 — Pure dose-reminder planning (the "decision"). Expands a schedule into
//  the calendar-trigger components the NotificationService turns into repeating
//  UNCalendarNotificationTriggers (the "effect"). No UserNotifications import:
//  this stays pure and testable.
//

import Foundation

extension DoseSchedule {
    /// The hour/minute (plus weekday, for weekly plans) of every dose this schedule
    /// fires across a day — one entry per repeating daily trigger.
    ///
    /// - `.daily`: one component per time of day.
    /// - `.weekdays`: one component per `(day × time)`, day-major, each tagged with the
    ///   `Calendar` weekday so the trigger fires only on that day.
    /// - `.everyNHours(n)`: the day is tiled from the **start time of day** in `n`-hour
    ///   steps. An 08:00 start every 8h fires at 08:00, 16:00, 00:00. `times` is ignored —
    ///   the rhythm is defined entirely by the interval anchored on `startDate`.
    ///
    /// Returns an empty array for a schedule that never fires (no times, no active days,
    /// or a non-positive interval).
    ///
    /// - Parameter calendar: used only to read the start time of day; injectable for tests.
    func doseTriggerComponents(calendar: Calendar = .current) -> [DateComponents] {
        switch frequency {
        case .daily:
            return times.map(Self.timeComponents)
        case .weekdays(let days):
            return days.flatMap { day in
                times.map { time in
                    var component = Self.timeComponents(time)
                    component.weekday = day.rawValue
                    return component
                }
            }
        case .everyNHours(let hours):
            return everyNHoursComponents(every: hours, calendar: calendar)
        }
    }

    /// Normalizes a stored time of day to explicit hour/minute, defaulting either to 0
    /// so a trigger matches a single instant rather than every minute of an hour.
    private static func timeComponents(_ time: DateComponents) -> DateComponents {
        DateComponents(hour: time.hour ?? 0, minute: time.minute ?? 0)
    }

    /// Tiles a 24-hour day from the start time of day in `hours`-hour steps.
    ///
    /// Produces `ceil(24 / hours)` components so the whole day is covered even when the
    /// interval does not divide 24; minutes past midnight wrap back into the day.
    private func everyNHoursComponents(every hours: Int, calendar: Calendar) -> [DateComponents] {
        guard hours > 0 else { return [] }
        let start = calendar.dateComponents([.hour, .minute], from: startDate)
        let anchorMinutes = (start.hour ?? 0) * 60 + (start.minute ?? 0)
        let stepMinutes = hours * 60
        let minutesPerDay = 24 * 60
        let count = Int((Double(minutesPerDay) / Double(stepMinutes)).rounded(.up))
        return (0..<count).map { step in
            let minuteOfDay = (anchorMinutes + step * stepMinutes) % minutesPerDay
            return DateComponents(hour: minuteOfDay / 60, minute: minuteOfDay % 60)
        }
    }
}
