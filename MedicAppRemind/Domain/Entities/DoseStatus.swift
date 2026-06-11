//
//  DoseStatus.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Lifecycle state of a single scheduled dose.
//

import Foundation

/// Lifecycle of a single scheduled dose.
///
/// `String` raw values keep the Codable/persistence representation stable.
enum DoseStatus: String, Codable, CaseIterable {
    /// Scheduled but not yet acted on.
    case pending
    /// Confirmed taken by the patient.
    case taken
    /// Deliberately skipped by the patient.
    case skipped
    /// Its scheduled time passed without action.
    case missed
}
