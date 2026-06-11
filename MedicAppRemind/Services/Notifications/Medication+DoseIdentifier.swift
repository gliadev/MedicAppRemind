//
//  Medication+DoseIdentifier.swift
//  MedicAppRemind
//
//  F3.S1 — Deterministic notification identifiers for a medication's dose reminders.
//  Determinism lets re-scheduling replace requests instead of duplicating them, and
//  lets cancellation match every reminder by a shared prefix.
//

import Foundation

extension Medication {
    /// The identifier prefix shared by every dose reminder of the medication with this id.
    /// Single source of truth so cancellation (which has only the id) matches scheduling.
    static func doseIdentifierPrefix(for id: UUID) -> String {
        "dose-\(id.uuidString)-"
    }

    /// The identifier shared by all of this medication's dose reminders.
    /// Cancellation removes every pending request whose identifier has this prefix.
    var doseIdentifierPrefix: String {
        Self.doseIdentifierPrefix(for: id)
    }

    /// A stable identifier for the reminder at the given trigger component.
    ///
    /// Built from the prefix plus the component's hour/minute/weekday, so two distinct
    /// trigger components of the same medication never collide and re-scheduling the same
    /// component reuses the same request.
    func doseIdentifier(for component: DateComponents) -> String {
        "\(doseIdentifierPrefix)\(component.hour ?? 0)-\(component.minute ?? 0)-\(component.weekday ?? 0)"
    }

    /// The identifier of the medication's single low-stock alert.
    ///
    /// One per medication (not per dose), so refreshing replaces it instead of stacking
    /// duplicates. A distinct namespace from the dose prefix keeps the two from colliding.
    static func lowStockIdentifier(for id: UUID) -> String {
        "lowstock-\(id.uuidString)"
    }

    /// The identifier of this medication's low-stock alert.
    var lowStockIdentifier: String {
        Self.lowStockIdentifier(for: id)
    }

    /// The identifier of this medication's pending "snooze" reminder.
    ///
    /// One per medication, in its own namespace, so postponing again replaces the
    /// previous snooze instead of stacking duplicates and never collides with a
    /// dose or low-stock reminder.
    var snoozeIdentifier: String {
        "snooze-\(id.uuidString)"
    }
}
