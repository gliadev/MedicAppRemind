//
//  CalendarSync.swift
//  MedicAppRemind
//
//  F4.S2 — The pure decision behind calendar reconciliation. Mirroring doses to the
//  system calendar is a small synchronization problem: diff the identities we already
//  created against the desired state, removing and recreating rather than blindly
//  recreating everything. CalendarSyncService performs the EventKit effect; this stays
//  testable without a store or an EKEventStore.
//

/// Why calendar sync is being reconciled. `.scheduleChanged` is emitted when the
/// dosing schedule is edited, so already-mirrored events can be rebuilt.
///
/// `Sendable` by construction — the conformance is inferred and must not be restated.
enum CalendarSyncIntent: Equatable {
    /// The patient turned calendar mirroring on.
    case enable
    /// The patient turned calendar mirroring off.
    case disable
    /// The dosing schedule changed; mirrored events (if any) must be rebuilt.
    case scheduleChanged
}

/// The reconciliation outcome: which previously-created events to remove, and whether
/// to create fresh ones from the current schedule. The newly created identifiers come
/// from the effect and become the next persisted state.
struct CalendarSyncPlan: Equatable {
    /// Identifiers of events that must be removed from the calendar.
    var identifiersToRemove: [String]
    /// Whether fresh events should be created from the current schedule.
    var createsEvents: Bool
}

extension CalendarSyncIntent {
    /// Reconciles this intent against the identifiers already mirrored to the calendar.
    ///
    /// Enabling and a schedule-change-while-synced both clear the existing events and
    /// recreate (EKEvent identities don't survive a recurrence change, so there is no
    /// partial overlap to preserve). Disabling clears without recreating. A schedule
    /// change while nothing is mirrored is a clean no-op — the patient never opted in.
    func reconcile(against storedIdentifiers: [String]) -> CalendarSyncPlan {
        switch self {
        case .enable:
            CalendarSyncPlan(identifiersToRemove: storedIdentifiers, createsEvents: true)
        case .disable:
            CalendarSyncPlan(identifiersToRemove: storedIdentifiers, createsEvents: false)
        case .scheduleChanged:
            storedIdentifiers.isEmpty
                ? CalendarSyncPlan(identifiersToRemove: [], createsEvents: false)
                : CalendarSyncPlan(identifiersToRemove: storedIdentifiers, createsEvents: true)
        }
    }
}
