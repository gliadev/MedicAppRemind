//
//  Medication+Validation.swift
//  MedicAppRemind
//
//  F1.S3 — Validates a medication's fields before it can be saved.
//

import Foundation

extension Medication {
    /// Returns the medication unchanged if its fields are clinically valid, otherwise throws.
    ///
    /// Checks name (at least one non-whitespace character), stock (non-negative) and pills
    /// per dose (strictly positive — also the divide-by-zero guard for `DoseMath`). Schedule
    /// validity is checked separately by `DoseSchedule.validated()`.
    @discardableResult
    func validated() throws -> Medication {
        guard name.contains(where: { !$0.isWhitespace }) else {
            throw ValidationError.emptyName
        }
        guard currentStock >= 0 else {
            throw ValidationError.negativeStock
        }
        guard pillsPerDose > 0 else {
            throw ValidationError.nonPositivePillsPerDose
        }
        return self
    }
}
