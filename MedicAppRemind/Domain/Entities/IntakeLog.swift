//
//  IntakeLog.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Record of a scheduled dose and its outcome.
//

import Foundation

/// A record of a scheduled dose and what actually happened with it.
///
/// References its medication by `UUID` rather than holding a reference, keeping
/// the domain free of object graphs — the join is rebuilt in persistence (F2).
struct IntakeLog: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var medicationID: UUID
    var scheduledAt: Date
    /// When the patient acted; `nil` while `status` is `.pending` or `.missed`.
    var takenAt: Date?
    var status: DoseStatus
    var pillsTaken: Double
}
