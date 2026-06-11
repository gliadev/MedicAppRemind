//
//  MedicationForm.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Physical presentation of a medication.
//

import Foundation

/// The physical presentation of a medication.
///
/// `String` raw values give a stable Codable representation across persistence
/// and CloudKit sync (F2/F7); adding a case must never reorder existing ones.
enum MedicationForm: String, Codable, CaseIterable {
    case pill
    case capsule
    case tablet
    case liquid
    case injection
    case other
}
