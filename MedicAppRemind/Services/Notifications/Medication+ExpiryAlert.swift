//
//  Medication+ExpiryAlert.swift
//  MedicAppRemind
//
//  FX.S4 — Pure expiry alert dates (the "decision"), mirroring the low-stock planner:
//  a heads-up `expiryWarningLeadDays` before expiry and one on the expiry day, each fired
//  at a fixed morning hour and clamped to today when already past. The NotificationService
//  turns these into one-shot triggers (the "effect"). No UserNotifications import.
//

import Foundation

/// Which of a medication's two expiry alerts a date belongs to — distinct so each gets a
/// stable notification identifier and the two never collide.
enum ExpiryAlertKind: String, Equatable, Sendable {
    /// The heads-up `expiryWarningLeadDays` before expiry.
    case upcoming
    /// The alert on the expiry day itself.
    case onExpiry
}

/// A single expiry reminder the planner has decided to schedule, in pure value form.
struct ExpiryAlert: Equatable, Sendable {
    var kind: ExpiryAlertKind
    var date: Date
}

extension Medication {
    /// Days before expiry to first warn the patient.
    static let expiryWarningLeadDays = 30
    /// The hour of day expiry alerts fire at — a morning reminder rather than midnight.
    static let expiryAlertHour = 9

    /// The reminders for this medication's approaching expiry: a heads-up
    /// `expiryWarningLeadDays` before it and one on the expiry day, each at
    /// `expiryAlertHour` and clamped to today when already in the past. When both collapse
    /// to the same instant (already expired) only the on-expiry alert is kept. Empty when
    /// no expiry is known.
    ///
    /// - Parameter calendar: injectable for deterministic tests.
    func expiryAlerts(from referenceDate: Date, calendar: Calendar = .current) -> [ExpiryAlert] {
        guard let expiryDate,
              let warningDay = calendar.date(byAdding: .day, value: -Self.expiryWarningLeadDays, to: expiryDate)
        else {
            return []
        }
        let today = calendar.startOfDay(for: referenceDate)

        func alertInstant(onDayOf day: Date) -> Date? {
            let clampedDay = max(calendar.startOfDay(for: day), today)
            return calendar.date(bySettingHour: Self.expiryAlertHour, minute: 0, second: 0, of: clampedDay)
        }

        guard let upcoming = alertInstant(onDayOf: warningDay),
              let onExpiry = alertInstant(onDayOf: expiryDate) else {
            return []
        }
        if upcoming == onExpiry {
            return [ExpiryAlert(kind: .onExpiry, date: onExpiry)]
        }
        return [
            ExpiryAlert(kind: .upcoming, date: upcoming),
            ExpiryAlert(kind: .onExpiry, date: onExpiry)
        ]
    }
}
