//
//  CalendarSyncService.swift
//  MedicAppRemind
//
//  F4.S2 — The effect side of calendar sync. It applies the pure CalendarSyncPlan
//  (CalendarSyncIntent.reconcile) by talking to the EventKit-backed CalendarService
//  and the persistence actor: removing stale events, creating fresh ones, and saving
//  the resulting identifiers. The decision stays pure and unit-tested; only this layer
//  performs side effects, so it isn't unit-tested against a live EKEventStore.
//

import Foundation

/// Reconciles a medication's calendar mirror with its desired state.
///
/// A plain `struct` over two actors, so it is `Sendable` by construction (the
/// conformance is inferred and must not be restated). Reusable from any screen — the
/// detail toggle today, the full detail screen in F6.S2.
struct CalendarSyncService {
    let calendarService: CalendarService
    let store: MedicationStoreActor

    /// How far ahead dose events are created. A bounded window keeps the calendar
    /// tidy; recurrence rules still repeat within it.
    static let dosingWindowDays = 90

    /// Applies `intent` to the medication and returns the identifiers now mirrored.
    ///
    /// Order matters: when events will be created, full access is requested first (so a
    /// fresh opt-in prompts before any removal). Stale events are then removed and new
    /// ones built from the current schedule. Persisting the result last keeps the stored
    /// identifiers in step with the calendar — no orphans.
    ///
    /// Degradable: if access was revoked between sessions, disabling still clears the
    /// stored identifiers even though the events can't be reached.
    @discardableResult
    func apply(_ intent: CalendarSyncIntent, to medicationID: UUID) async throws -> [String] {
        let stored = try await store.calendarEventIDs(medicationID: medicationID)
        let plan = intent.reconcile(against: stored)

        if plan.createsEvents {
            guard try await calendarService.requestAccess() else { throw CalendarError.accessDenied }
        }

        if !plan.identifiersToRemove.isEmpty {
            do {
                try await calendarService.removeEvents(identifiers: plan.identifiersToRemove)
            } catch CalendarError.accessDenied where !plan.createsEvents {
                // Permission revoked between sessions: the events are unreachable, but we
                // still clear our tracking below so stale identifiers don't linger.
            }
        }

        var created: [String] = []
        if plan.createsEvents, let medicationPlan = try await store.plan(id: medicationID) {
            for schedule in medicationPlan.schedules {
                created += try await calendarService.addDoseEvents(
                    for: medicationPlan.medication,
                    schedule: schedule,
                    days: Self.dosingWindowDays
                )
            }
        }

        try await store.setCalendarEventIDs(created, medicationID: medicationID)
        return created
    }

    /// Adds a one-shot "refill" reminder on the medication's projected refill date
    /// (`DoseMath.refillDate`). Returns the event identifier, or `nil` when the
    /// medication has no schedule or an undefined consumption rate (nothing to predict).
    @discardableResult
    func addRefillReminder(for medicationID: UUID, calendar: Calendar = .current) async throws -> String? {
        guard let medicationPlan = try await store.plan(id: medicationID),
              let schedule = medicationPlan.schedules.first,
              let refillDate = medicationPlan.medication.refillDate(from: .now, for: schedule, calendar: calendar)
        else { return nil }

        guard try await calendarService.requestAccess() else { throw CalendarError.accessDenied }
        return try await calendarService.addRefillReminder(for: medicationPlan.medication, on: refillDate)
    }
}
