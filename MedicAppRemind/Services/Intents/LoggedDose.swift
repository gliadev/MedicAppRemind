//
//  LoggedDose.swift
//  MedicAppRemind
//
//  F5.S2 — The testable core of `LogDoseIntent`. Reuses the F3 `recordedDose`
//  reducer and the store's idempotent `recordIntake`, so a dose logged by voice
//  means exactly what a dose logged from a notification means — one definition of
//  "log a dose", no duplicated clinical logic.
//

import Foundation

/// The outcome of logging a dose, ready for the intent's spoken confirmation.
struct LoggedDose: Equatable, Sendable {
    var medicationName: String
    var remainingPills: Double
}

/// Logs a taken dose for a medication and reports the remaining stock.
///
/// Idempotent by occurrence: the same medication at the same instant maps to one
/// `IntakeLog`, so a double invocation of one `perform()` never double-decrements.
///
/// - Parameters:
///   - medicationID: which medication was taken.
///   - store: the persistence actor (the shared store in production; an in-memory
///     one in tests).
///   - instant: when the dose was taken — both the log's timing and the seed for
///     its deterministic occurrence id.
func logDose(
    medicationID: UUID,
    using store: MedicationStoreActor,
    at instant: Date
) async throws -> LoggedDose {
    guard let medication = try await store.medication(id: medicationID) else {
        throw IntentError.medicationNotFound
    }
    let recorded = recordedDose(
        for: medication,
        scheduledAt: instant,
        takenAt: instant,
        logID: doseOccurrenceID(medicationID: medicationID, scheduledAt: instant)
    )
    _ = try await store.recordIntake(recorded.log, decrementingStockBy: recorded.stockDecrement)
    let remaining = try await store.medication(id: medicationID)?.currentStock ?? medication.currentStock
    return LoggedDose(medicationName: medication.name, remainingPills: remaining)
}
