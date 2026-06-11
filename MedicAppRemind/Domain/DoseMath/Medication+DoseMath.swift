//
//  Medication+DoseMath.swift
//  MedicAppRemind
//
//  F1.S2 — Pure dose math. Remaining supply, refill date and low-stock check.
//

import Foundation

extension Medication {
    /// Days of supply remaining at the given schedule's consumption rate.
    ///
    /// `currentStock / (pillsPerDose × schedule.dosesPerDay)`, returned as an exact
    /// `Double` — the presentation layer decides any rounding. Returns `nil` when the
    /// rate is undefined: a schedule that never fires (`dosesPerDay == 0`) or a
    /// non-positive `pillsPerDose`, both of which would otherwise divide by zero.
    func remainingDays(for schedule: DoseSchedule) -> Double? {
        let dosesPerDay = schedule.dosesPerDay
        guard dosesPerDay > 0, pillsPerDose > 0 else { return nil }
        return currentStock / (pillsPerDose * dosesPerDay)
    }

    /// The day stock is exhausted: `date` advanced by the whole number of remaining days.
    ///
    /// Floors `remainingDays` to whole days (the last day a full dose is available) and
    /// advances `date` using the injected `calendar`. Returns `nil` when `remainingDays`
    /// is undefined.
    func refillDate(from date: Date, for schedule: DoseSchedule, calendar: Calendar = .current) -> Date? {
        guard let remaining = remainingDays(for: schedule) else { return nil }
        let wholeDays = Int(remaining.rounded(.down))
        return calendar.date(byAdding: .day, value: wholeDays, to: date)
    }

    /// Whether remaining supply has fallen to or below the low-stock threshold (in days).
    ///
    /// `false` when the rate is undefined (`remainingDays == nil`): a medication that is
    /// never consumed cannot run low.
    func isLowStock(for schedule: DoseSchedule) -> Bool {
        guard let remaining = remainingDays(for: schedule) else { return false }
        return remaining <= Double(lowStockThresholdDays)
    }
}
