//
//  ReminderPlan.swift
//  MedicAppRemind
//
//  F3.S2 — Pure reminder planning across all medications (the "decision"). Expands
//  each plan into dose and low-stock reminders, orders them by next fire date and
//  truncates to the 64 pending-notification cap iOS enforces. NotificationService
//  turns the result into UNNotificationRequests (the "effect"); this stays testable.
//

import Foundation

/// A medication paired with its active dose schedules — the unit the reminder planner
/// expands. The caller builds it from SwiftData, so no `@Model` instance ever crosses
/// into `NotificationService`.
struct MedicationPlan: Equatable, Sendable {
    var medication: Medication
    var schedules: [DoseSchedule]
}

/// A single local notification the planner has decided to schedule, in pure value form.
/// `NotificationService` turns each into a `UNNotificationRequest`; tests assert on these
/// without touching `UNUserNotificationCenter`.
struct PlannedReminder: Equatable, Sendable {
    /// What the reminder is for — drives the notification's wording.
    enum Kind: Equatable, Sendable {
        case dose
        case lowStock
        case expiry
    }

    /// iOS silently drops pending local notifications beyond this many per app, so the
    /// planner never emits more — nearest reminders win and the rest are reprogrammed
    /// when the app next opens.
    static let maxPending = 64

    var identifier: String
    var medicationID: UUID
    var kind: Kind
    /// Calendar-match components: a time of day (repeating dose) or a full day-and-time
    /// (one-shot low-stock alert).
    var component: DateComponents
    /// `true` for repeating dose reminders, `false` for the one-shot low-stock alert.
    var repeats: Bool
    /// The instant this reminder next fires — used only to order reminders under the
    /// `maxPending` cap. Nearest first.
    var nextFireDate: Date
}

/// Expands medication plans into the local reminders to schedule, nearest first and
/// capped at `limit`.
///
/// For each plan: one repeating reminder per dose-trigger component across all of its
/// schedules, plus at most one low-stock alert at the soonest threshold crossing among
/// those schedules. The merged set is ordered by `nextFireDate` and truncated to `limit`
/// — the 64-cap policy in pure form, unit-tested without the notification center.
///
/// - Parameter referenceDate: "now"; injectable so tests are deterministic.
func plannedReminders(
    for plans: [MedicationPlan],
    from referenceDate: Date,
    calendar: Calendar = .current,
    limit: Int = PlannedReminder.maxPending
) -> [PlannedReminder] {
    let candidates = plans.flatMap { plan in
        doseReminders(for: plan, from: referenceDate, calendar: calendar)
            + lowStockReminders(for: plan, from: referenceDate, calendar: calendar)
            + expiryReminders(for: plan, from: referenceDate, calendar: calendar)
    }
    let ordered = candidates.sorted { $0.nextFireDate < $1.nextFireDate }
    return Array(ordered.prefix(limit))
}

/// Every repeating dose reminder a plan fires across its schedules, each tagged with its
/// next occurrence after `referenceDate` for prioritization.
private func doseReminders(for plan: MedicationPlan, from referenceDate: Date, calendar: Calendar) -> [PlannedReminder] {
    let medication = plan.medication
    return plan.schedules.flatMap { schedule in
        schedule.doseTriggerComponents(calendar: calendar).compactMap { component -> PlannedReminder? in
            guard let next = calendar.nextDate(after: referenceDate, matching: component, matchingPolicy: .nextTime) else {
                return nil
            }
            return PlannedReminder(
                identifier: medication.doseIdentifier(for: component),
                medicationID: medication.id,
                kind: .dose,
                component: component,
                repeats: true,
                nextFireDate: next
            )
        }
    }
}

/// The medication's single low-stock alert, at the soonest threshold crossing among its
/// schedules (the most conservative warning). Empty when no schedule defines a rate.
private func lowStockReminders(for plan: MedicationPlan, from referenceDate: Date, calendar: Calendar) -> [PlannedReminder] {
    let medication = plan.medication
    let soonest = plan.schedules
        .compactMap { medication.lowStockAlertDate(from: referenceDate, for: $0, calendar: calendar) }
        .min()
    guard let alertDate = soonest else { return [] }
    let component = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
    return [PlannedReminder(
        identifier: medication.lowStockIdentifier,
        medicationID: medication.id,
        kind: .lowStock,
        component: component,
        repeats: false,
        nextFireDate: alertDate
    )]
}

/// The medication's expiry alerts (a heads-up before expiry and one on the day), each a
/// one-shot reminder tagged with its fire date for prioritization. Empty when no expiry
/// is known.
private func expiryReminders(for plan: MedicationPlan, from referenceDate: Date, calendar: Calendar) -> [PlannedReminder] {
    let medication = plan.medication
    return medication.expiryAlerts(from: referenceDate, calendar: calendar).map { alert in
        let component = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alert.date)
        return PlannedReminder(
            identifier: medication.expiryIdentifier(for: alert.kind),
            medicationID: medication.id,
            kind: .expiry,
            component: component,
            repeats: false,
            nextFireDate: alert.date
        )
    }
}
