//
//  MedicationDraft.swift
//  MedicAppRemind
//
//  F10.S1 — Quick-add draft. The structured-but-unvalidated result of parsing
//  a free-text medication description. Never persisted: it only prefills the
//  editor, whose save path remains the single gate into SwiftData.
//

import Foundation

/// A medication described in free text, structured but not yet validated.
///
/// Every field is optional — the editor prefills only what the text carried.
/// `lowStockThresholdDays` is deliberately absent: it is never drafted, the
/// app's default always applies.
struct MedicationDraft: Equatable {
    var name: String? = nil
    var doseLabel: String? = nil
    var pillsPerDose: Double? = nil
    var form: MedicationForm? = nil
    var currentStock: Double? = nil
    var schedule: DraftSchedule? = nil
    /// The verbatim text the draft was parsed from. Preserved into the
    /// editor's notes when anything downstream fails, so nothing the user
    /// said (or dictated) is ever lost.
    var sourceText: String
}
