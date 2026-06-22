//
//  NotificationService.swift
//  MedicAppRemind
//
//  F3.S1 — Local dose reminders (the "effect"). The planning is pure and tested
//  (see DoseSchedule+DoseTriggers); this layer turns those components into repeating
//  UNCalendarNotificationTriggers. The notification center is resolved per call rather
//  than stored, since UNUserNotificationCenter is not Sendable.
//

import Foundation
import UserNotifications

/// Schedules and cancels local notifications for medication doses.
///
/// An `actor` so reminder bookkeeping is serialized off the main thread; UI presentation
/// (F3.S3 delegate) is the only part that needs the main actor.
actor NotificationService {

    /// Requests permission for alerts, sound and badge. Returns `false` if denied or on
    /// error, so callers can degrade gracefully rather than assume reminders will fire.
    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        return granted ?? false
    }

    /// Replaces this medication's dose reminders with one repeating trigger per planned
    /// component. Cancels first so re-scheduling never duplicates.
    func scheduleDoseReminders(for medication: Medication, schedule: DoseSchedule) async {
        await cancelReminders(for: medication.id)
        let center = UNUserNotificationCenter.current()
        for component in schedule.doseTriggerComponents() {
            let content = makeContent(for: .dose, medication: medication)
            let trigger = UNCalendarNotificationTrigger(dateMatching: component, repeats: true)
            let request = UNNotificationRequest(
                identifier: medication.doseIdentifier(for: component),
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// Removes every pending reminder belonging to the medication, matched by its
    /// deterministic identifier prefix.
    func cancelReminders(for medicationID: UUID) async {
        let prefix = Medication.doseIdentifierPrefix(for: medicationID)
        let center = UNUserNotificationCenter.current()
        let identifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    /// Replaces this medication's low-stock alert with a one-shot reminder on the day its
    /// remaining supply crosses the threshold (today if already below it). Cancels first so
    /// re-scheduling never duplicates; a no-op when the consumption rate is undefined.
    ///
    /// - Parameter referenceDate: "now"; injectable for tests.
    func scheduleLowStockAlert(
        for medication: Medication,
        schedule: DoseSchedule,
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [medication.lowStockIdentifier])
        guard let alertDate = medication.lowStockAlertDate(from: referenceDate, for: schedule, calendar: calendar) else {
            return
        }
        let component = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: component, repeats: false)
        let request = UNNotificationRequest(
            identifier: medication.lowStockIdentifier,
            content: makeContent(for: .lowStock, medication: medication),
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Recomputes and reprograms every medication's reminders, honoring the 64 pending
    /// limit. Called on app launch and after each intake (stock changed → refill date
    /// moved). Clears all pending requests first, so it is idempotent.
    ///
    /// - Parameter referenceDate: "now"; injectable for tests.
    func refreshAllReminders(
        for plans: [MedicationPlan],
        from referenceDate: Date = .now,
        calendar: Calendar = .current
    ) async {
        let reminders = plannedReminders(for: plans, from: referenceDate, calendar: calendar)
        let medicationsByID = Dictionary(plans.map { ($0.medication.id, $0.medication) }) { first, _ in first }
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        for reminder in reminders {
            guard let medication = medicationsByID[reminder.medicationID] else { continue }
            let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.component, repeats: reminder.repeats)
            let request = UNNotificationRequest(
                identifier: reminder.identifier,
                content: makeContent(for: reminder.kind, medication: medication),
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// Registers the actionable dose category, so dose reminders show the
    /// "Tomada"/"Posponer" buttons. Call once at launch, before the first reminder
    /// is scheduled.
    func registerDoseCategory() {
        UNUserNotificationCenter.current().setNotificationCategories([.makeDose()])
    }

    /// Schedules a one-shot reminder `DoseAction.snoozeInterval` from now for the
    /// "Posponer" action. Replaces any pending snooze for the same medication so
    /// repeated postponing never stacks.
    func scheduleSnooze(for medication: Medication) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [medication.snoozeIdentifier])
        let seconds = Double(DoseAction.snoozeInterval.components.seconds)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        let request = UNNotificationRequest(
            identifier: medication.snoozeIdentifier,
            content: makeContent(for: .dose, medication: medication),
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Builds localized notification content for a reminder kind, carrying the
    /// `medicationID` in `userInfo` for the F3.S3 deep-link and tagging dose
    /// reminders with the actionable category.
    ///
    /// The body is intentionally generic — medication names are clinical data and
    /// must not appear on the lock screen. The deep-link in `userInfo` routes the
    /// user to the full detail once the device is unlocked.
    private func makeContent(for kind: PlannedReminder.Kind, medication: Medication) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        switch kind {
        case .dose:
            content.title = String(localized: "Hora de tu medicación")
            content.body = Self.notificationBody(for: .dose)
            content.categoryIdentifier = UNNotificationCategory.doseIdentifier
        case .lowStock:
            content.title = String(localized: "Stock bajo")
            content.body = Self.notificationBody(for: .lowStock)
        }
        content.sound = .default
        content.userInfo = DosePayload(medicationID: medication.id).userInfo
        return content
    }

    /// Returns the notification body for a given reminder kind.
    ///
    /// Extracted as `static nonisolated` so tests can assert the privacy guarantee
    /// (no PHI on the lock screen) without instantiating the actor or mocking
    /// `UNUserNotificationCenter`.
    static nonisolated func notificationBody(for kind: PlannedReminder.Kind) -> String {
        switch kind {
        case .dose: String(localized: "Tienes una toma pendiente.")
        case .lowStock: String(localized: "Recarga tu medicación pronto.")
        }
    }
}
