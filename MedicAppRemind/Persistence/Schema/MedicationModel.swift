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

    @Relationship(deleteRule: .cascade, inverse: \DoseScheduleModel.medication)
    var schedules: [DoseScheduleModel]? = []

    @Relationship(deleteRule: .cascade, inverse: \IntakeLogModel.medication)
    var intakeLogs: [IntakeLogModel]? = []

    init() {}
}
