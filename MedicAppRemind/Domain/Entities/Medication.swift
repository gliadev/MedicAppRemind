//
//  Medication.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Pure value type, no SwiftUI/SwiftData.
//  The SwiftData mapping (MedicationModel) lives in F2.
//

import Foundation

/// A medication the patient tracks: identity, presentation, dosing and stock.
///
/// `Sendable` by construction — every stored property is itself `Sendable`,
/// so the conformance is inferred and must not be restated.
struct Medication: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var notes: String
    var form: MedicationForm
    /// Human-readable dose label, e.g. "600 mg". Presentation only; never parsed for math.
    var doseLabel: String
    /// Pills consumed per single dose. Drives `DoseMath` (F1.S2); must be > 0 to be valid (F1.S3).
    var pillsPerDose: Double
    /// Remaining units in stock. Never negative for valid data (validated in F1.S3).
    var currentStock: Double
    /// Days of remaining stock below which the medication is considered low.
    var lowStockThresholdDays: Int
    var createdAt: Date
    var updatedAt: Date
    /// Nearest expiry date across the boxes on hand, from a scanned DataMatrix (FX). The
    /// expiry planner turns it into refill/discard alerts; `nil` when never scanned.
    var expiryDate: Date? = nil
    /// Código Nacional (6 digits) the medication was scanned/created from (FX). Lets a new
    /// scan match this record and merge stock; `nil` for manually entered medications.
    var nationalCode: String? = nil
}
