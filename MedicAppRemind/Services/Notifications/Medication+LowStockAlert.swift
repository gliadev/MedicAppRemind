//
//  Medication+LowStockAlert.swift
//  MedicAppRemind
//
//  F3.S2 — Pure low-stock alert date (the "decision"). Derived entirely from
//  `refillDate` so the clinical formula lives in one place; the NotificationService
//  turns this date into a one-shot trigger (the "effect"). No UserNotifications import.
//

import Foundation

extension Medication {
    /// The day this medication's remaining supply crosses the low-stock threshold —
    /// the moment to warn the patient to refill.
    ///
    /// Built from `refillDate` (the single clinical formula): if stock lasts until the
    /// exhaustion day, the threshold is crossed `lowStockThresholdDays` days earlier.
    /// When stock is already at or below the threshold that day is in the past, so it is
    /// clamped to `date` (alert today). Returns `nil` when the consumption rate is
    /// undefined — a never-consumed medication can't run low.
    ///
    /// - Parameter calendar: injectable for deterministic tests.
    func lowStockAlertDate(from date: Date, for schedule: DoseSchedule, calendar: Calendar = .current) -> Date? {
        guard let refill = refillDate(from: date, for: schedule, calendar: calendar),
              let alert = calendar.date(byAdding: .day, value: -lowStockThresholdDays, to: refill) else {
            return nil
        }
        return max(alert, date)
    }
}
