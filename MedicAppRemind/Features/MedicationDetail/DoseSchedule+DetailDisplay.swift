//
//  DoseSchedule+DetailDisplay.swift
//  MedicAppRemind
//
//  v1.2 — The detail screen's schedule section must mirror the pauta the editor saved.
//  AX-04 added `.weekdays` and `.everyNHours`, but the detail listed only `schedule.times`
//  sorted by hour: an interval pauta (which stores no `times`) rendered an empty section,
//  and a weekly pauta gave no hint of which days it fired on. This derives, as pure value
//  logic, the dose times the section should show — reusing the trigger expansion for
//  intervals so the rhythm is never re-derived here.
//

import Foundation

extension DoseSchedule {
    /// The dose times to list in the detail's schedule section, sorted chronologically
    /// within the day.
    ///
    /// - `.daily` / `.weekdays`: the stored `times`. For weekly pautas the *days* are shown
    ///   in the section title, so each time of day appears once, not repeated per day.
    /// - `.everyNHours`: `times` is empty by design, so the real fire times come from the
    ///   trigger expansion anchored on `startDate`.
    func displayDoseTimes(calendar: Calendar = .current) -> [DateComponents] {
        let raw: [DateComponents]
        switch frequency {
        case .daily, .weekdays:
            raw = times
        case .everyNHours:
            raw = doseTriggerComponents(calendar: calendar)
        }
        return raw
            .map { DateComponents(hour: $0.hour ?? 0, minute: $0.minute ?? 0) }
            .sorted { Self.minuteOfDay($0) < Self.minuteOfDay($1) }
    }

    private static func minuteOfDay(_ time: DateComponents) -> Int {
        (time.hour ?? 0) * 60 + (time.minute ?? 0)
    }
}
