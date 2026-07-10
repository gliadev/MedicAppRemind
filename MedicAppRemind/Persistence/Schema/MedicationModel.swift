//
//  MedicationModel.swift
//  MedicAppRemind
//
//  F2.S1 — SwiftData persistence model for `Medication`. CloudKit-safe:
//  every property has a default, every relationship is optional with an
//  explicit inverse, and there is no `@Attribute(.unique)`.
//

import Foundation
import SwiftData

/// SwiftData record for a medication. Logical identity is `id`, deduplicated in
/// the `@ModelActor` (F2.S2) — never with `@Attribute(.unique)`, which CloudKit
/// forbids. The enum-typed `form` is persisted as its `rawValue` in `formRaw`.
@Model
final class MedicationModel {
    var id: UUID = UUID()
    var name: String = ""
    var notes: String = ""
    var formRaw: String = MedicationForm.pill.rawValue
    var doseLabel: String = ""
    var pillsPerDose: Double = 1
    var currentStock: Double = 0
    var lowStockThresholdDays: Int = 7
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    /// Nearest expiry across the boxes on hand (FX.S4), from a scanned DataMatrix.
    /// Optional and defaulted, keeping the schema CloudKit-safe.
    var expiryDate: Date? = nil

    /// Código Nacional the medication was scanned/created from (FX.S4), so a later scan
    /// of the same product matches this record. Not `@Attribute(.unique)` — CloudKit
    /// forbids it; logical dedup happens in the actor.
    var nationalCode: String? = nil

    /// JSON-encoded `[String]` of the serials of boxes already scanned into this
    /// medication (FX.S4), or `nil` when none. Stored as `Data?` so the schema stays
    /// CloudKit-safe. Access it through the decoded `scannedSerials` convenience.
    var scannedSerialsData: Data? = nil

    /// JSON-encoded `[String]` of calendar `eventIdentifier`s mirrored for this
    /// medication (F4.S2), or `nil` when it isn't mirrored. Stored as `Data?` so the
    /// schema stays CloudKit-safe (optional, defaulted). Access it through the decoded
    /// `calendarEventIDs` convenience rather than this raw field.
    var calendarEventIDsData: Data? = nil

    @Relationship(deleteRule: .cascade, inverse: \DoseScheduleModel.medication)
    var schedules: [DoseScheduleModel]? = []

    @Relationship(deleteRule: .cascade, inverse: \IntakeLogModel.medication)
    var intakeLogs: [IntakeLogModel]? = []

    init() {}
}
