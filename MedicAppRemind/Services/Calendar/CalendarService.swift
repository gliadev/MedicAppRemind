//
//  CalendarService.swift
//  MedicAppRemind
//
//  F4.S1 — The effect: writes the patient's doses and refill date to the system calendar.
//  The decisions (frequency → recurrence, schedule → event seeds) are pure and unit-tested
//  in DoseFrequency.recurrence / DoseSchedule.calendarEventSeeds; this layer only performs
//  the EventKit side effects. Integration is optional and degradable: every entry point
//  throws CalendarError rather than crashing when access is missing.
//

import Foundation
import EventKit

/// Bridges the app's dosing model to the system calendar via EventKit.
///
/// An `actor`: it owns a single long-lived, non-`Sendable` `EKEventStore` (Apple recommends
/// one store per app) and serializes access to it. Being an actor also makes the service
/// `Sendable`, satisfying the spec without `@unchecked` tricks.
actor CalendarService {
    private let eventStore: EKEventStore

    /// - Parameter eventStore: injectable so tests can supply a stub; defaults to a fresh store.
    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    /// Requests full calendar access using the modern iOS 17 API
    /// (`requestFullAccessToEvents()`, not the deprecated `requestAccess(to:)`).
    /// Returns whether access was granted.
    func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    /// Creates one recurring event per dose anchor across the next `days` and returns their
    /// `eventIdentifier`s so they can be removed later (the dedup/cleanup key for F4.S2).
    ///
    /// Throws `.accessDenied` without full access and `.saveFailed` if a save fails. Returns
    /// `[]` for a schedule that never recurs.
    func addDoseEvents(for medication: Medication, schedule: DoseSchedule, days: Int) async throws -> [String] {
        try ensureFullAccess()
        guard let recurrence = schedule.frequency.recurrence else { return [] }

        let calendar = Calendar.current
        let referenceStart = max(.now, schedule.startDate)
        let until = calendar.date(byAdding: .day, value: days, to: referenceStart)
        let rule = recurrence.ekRecurrenceRule(until: until)

        var identifiers: [String] = []
        for seed in schedule.calendarEventSeeds(calendar: calendar) {
            guard let start = calendar.nextDate(after: referenceStart, matching: seed, matchingPolicy: .nextTime) else {
                continue
            }
            let event = makeEvent(title: doseTitle(for: medication), start: start, calendar: calendar)
            event.recurrenceRules = [rule]
            do {
                try eventStore.save(event, span: .futureEvents)
            } catch {
                throw CalendarError.saveFailed
            }
            if let identifier = event.eventIdentifier {
                identifiers.append(identifier)
            }
        }
        return identifiers
    }

    /// Adds a one-shot all-day "refill" reminder on `date` and returns its `eventIdentifier`.
    /// Throws `.accessDenied` without access and `.saveFailed` on failure.
    func addRefillReminder(for medication: Medication, on date: Date) async throws -> String {
        try ensureFullAccess()
        let day = Calendar.current.startOfDay(for: date)
        let event = EKEvent(eventStore: eventStore)
        event.title = String(localized: "Recargar \(medication.name)")
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.isAllDay = true
        event.startDate = day
        event.endDate = day
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw CalendarError.saveFailed
        }
        guard let identifier = event.eventIdentifier else { throw CalendarError.saveFailed }
        return identifier
    }

    /// Removes events by identifier. Missing events are skipped (already gone); a failed
    /// removal throws `.saveFailed`. Revalidates access first so a revoked permission
    /// degrades cleanly instead of crashing.
    func removeEvents(identifiers: [String]) async throws {
        try ensureFullAccess()
        for identifier in identifiers {
            guard let event = eventStore.event(withIdentifier: identifier) else { continue }
            do {
                try eventStore.remove(event, span: .futureEvents)
            } catch {
                throw CalendarError.saveFailed
            }
        }
    }

    // MARK: - Helpers

    /// Throws `.accessDenied` unless the app currently holds full calendar access.
    private func ensureFullAccess() throws {
        guard EKEventStore.authorizationStatus(for: .event) == .fullAccess else {
            throw CalendarError.accessDenied
        }
    }

    private func makeEvent(title: String, start: Date, calendar: Calendar) -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = eventStore.defaultCalendarForNewEvents
        event.startDate = start
        // A short, fixed dose duration — the reminder matters more than the block length.
        event.endDate = calendar.date(byAdding: .minute, value: 15, to: start) ?? start
        return event
    }

    private func doseTitle(for medication: Medication) -> String {
        String(localized: "Tomar \(medication.name) (\(medication.doseLabel))")
    }
}
