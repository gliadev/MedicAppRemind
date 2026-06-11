//
//  ValidationError.swift
//  MedicAppRemind
//
//  F1.S3 — Domain validation errors. First line of clinical defence:
//  invalid data must never reach the dose math.
//

import Foundation

/// Reasons a `Medication` or its `DoseSchedule` fails validation before it can be saved.
///
/// `LocalizedError` already refines `Error`, so `Error` is not restated. Descriptions
/// come from the string catalog via `String(localized:)`; Xcode extracts the keys on build.
enum ValidationError: LocalizedError {
    /// The medication name is empty or whitespace-only.
    case emptyName
    /// The remaining stock is negative.
    case negativeStock
    /// Pills per dose is zero or negative.
    case nonPositivePillsPerDose
    /// The dose schedule never fires (no times, no active days, or a non-positive interval).
    case emptySchedule

    var errorDescription: String? {
        switch self {
        case .emptyName:
            String(localized: "validationError.emptyName",
                   defaultValue: "El nombre del medicamento no puede estar vacío.",
                   comment: "Validation error shown when saving a medication without a name")
        case .negativeStock:
            String(localized: "validationError.negativeStock",
                   defaultValue: "Las existencias no pueden ser negativas.",
                   comment: "Validation error shown when the stock value is below zero")
        case .nonPositivePillsPerDose:
            String(localized: "validationError.nonPositivePillsPerDose",
                   defaultValue: "Las pastillas por toma deben ser mayores que cero.",
                   comment: "Validation error shown when pills per dose is zero or negative")
        case .emptySchedule:
            String(localized: "validationError.emptySchedule",
                   defaultValue: "La pauta debe tener al menos una toma programada.",
                   comment: "Validation error shown when the schedule has no doses")
        }
    }
}
