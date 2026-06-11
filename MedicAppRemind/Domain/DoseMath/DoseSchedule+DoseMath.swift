//
//  DoseSchedule+DoseMath.swift
//  MedicAppRemind
//
//  F1.S2 — Pure dose math. Consumption rate derived from a schedule.
//

import Foundation

extension DoseSchedule {
    /// Average number of doses taken per day for this schedule.
    ///
    /// - `.daily`: one dose per listed time of day (`times.count`).
    /// - `.weekdays`: the daily dose count averaged over the week
    ///   (`times.count × activeDays / 7`), so a Mon/Wed/Fri once-a-day plan is `3/7`.
    /// - `.everyNHours(n)`: `24 / n` doses across the day, independent of `times`.
    ///
    /// Returns `0` for a schedule that never fires (no times, no active days, or a
    /// non-positive interval); callers read that as "no consumption".
    var dosesPerDay: Double {
        switch frequency {
        case .daily:
            return Double(times.count)
        case .weekdays(let days):
            return Double(times.count) * Double(days.count) / 7
        case .everyNHours(let hours):
            guard hours > 0 else { return 0 }
            return 24 / Double(hours)
        }
    }
}
