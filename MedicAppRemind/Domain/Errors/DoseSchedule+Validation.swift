//
//  DoseSchedule+Validation.swift
//  MedicAppRemind
//
//  F1.S3 — Validates that a schedule actually fires.
//

import Foundation

extension DoseSchedule {
    /// Returns the schedule unchanged if it fires at least once a day, otherwise throws.
    ///
    /// A schedule with no times, no active weekdays, or a non-positive interval has a
    /// `dosesPerDay` of `0` and would never remind the patient — that is invalid.
    @discardableResult
    func validated() throws -> DoseSchedule {
        guard dosesPerDay > 0 else {
            throw ValidationError.emptySchedule
        }
        return self
    }
}
