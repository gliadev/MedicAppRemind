//
//  MedicationEditorAccessibility.swift
//  MedicAppRemind
//
//  F6.S3 — Editor field identity for @AccessibilityFocusState, plus the pure
//  function that maps a set of ValidationErrors to the highest-priority field
//  VoiceOver should jump to after a failed save attempt.
//

import Foundation

/// Identifies a focusable field in `MedicationEditorView`.
///
/// Used with `@AccessibilityFocusState` so that VoiceOver jumps automatically
/// to the first invalid field when the user taps "Guardar" with errors present.
enum EditorField: Hashable {
    case name
    case pillsPerDose
    case stock
    case schedule
}

extension EditorField {
    /// Returns the highest-priority field that should receive VoiceOver focus,
    /// given the set of active validation errors. Returns `nil` when there are none.
    ///
    /// Priority mirrors the validation order in `Medication.validated()`:
    /// name → pillsPerDose → stock → schedule.
    static func firstInvalidField(for errors: Set<ValidationError>) -> EditorField? {
        if errors.contains(.emptyName)               { return .name }
        if errors.contains(.nonPositivePillsPerDose) { return .pillsPerDose }
        if errors.contains(.negativeStock)           { return .stock }
        if errors.contains(.emptySchedule)           { return .schedule }
        return nil
    }
}
