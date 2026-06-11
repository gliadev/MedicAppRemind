//
//  PersistenceError.swift
//  MedicAppRemind
//
//  F2 — Data-integrity errors raised while mapping persistence models back to
//  domain value types. Internal to the persistence layer (not user-facing), so
//  it is a plain `Error` with no localized description.
//

import Foundation

/// A persistence record could not be mapped to a valid domain value.
enum PersistenceError: Error {
    /// A `DoseScheduleModel` is missing its encoded frequency/times payload, or
    /// the payload failed to decode.
    case corruptedScheduleData
    /// An `IntakeLogModel` has no owning medication, so it has no `medicationID`.
    case orphanIntakeLog
}
