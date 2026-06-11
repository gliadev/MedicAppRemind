//
//  RecordedDose.swift
//  MedicAppRemind
//
//  F3.S3 — The pure intake reducer "Tomada" applies, shared with the F5 App
//  Intents so a logged dose means exactly one thing across the app. Given a
//  medication and the occurrence's timing, it yields the `IntakeLog` to persist
//  and how much stock to subtract. No persistence, no notification center.
//

import Foundation
import CryptoKit

/// The effect of confirming a dose: the log to persist and the stock to subtract.
struct RecordedDose: Equatable, Sendable {
    var log: IntakeLog
    var stockDecrement: Double
}

/// Builds the intake for a confirmed dose. A taken dose consumes exactly one
/// dose's worth of pills (`pillsPerDose`), recorded and subtracted together.
///
/// - Parameters:
///   - medication: the medication taken; supplies `pillsPerDose`.
///   - scheduledAt: when the dose was scheduled to fire.
///   - takenAt: when the patient confirmed it.
///   - logID: the intake log's id — pass a deterministic id (see
///     `doseOccurrenceID`) so re-handling the same notification stays idempotent.
func recordedDose(
    for medication: Medication,
    scheduledAt: Date,
    takenAt: Date,
    logID: UUID
) -> RecordedDose {
    let log = IntakeLog(
        id: logID,
        medicationID: medication.id,
        scheduledAt: scheduledAt,
        takenAt: takenAt,
        status: .taken,
        pillsTaken: medication.pillsPerDose
    )
    return RecordedDose(log: log, stockDecrement: medication.pillsPerDose)
}

/// A deterministic id for a specific dose occurrence (a medication at a scheduled
/// instant). The same occurrence always hashes to the same id, so a double tap of
/// one delivered notification maps to one intake log — the store can then make the
/// write idempotent. Derived from a SHA-256 of the medication id and the exact
/// scheduled instant; collision-resistant and independent of time zone.
func doseOccurrenceID(medicationID: UUID, scheduledAt: Date) -> UUID {
    let key = "\(medicationID.uuidString)|\(scheduledAt.timeIntervalSinceReferenceDate.bitPattern)"
    let digest = SHA256.hash(data: Data(key.utf8))
    let bytes = Array(digest.prefix(16))
    return UUID(uuid: (
        bytes[0], bytes[1], bytes[2], bytes[3],
        bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11],
        bytes[12], bytes[13], bytes[14], bytes[15]
    ))
}
