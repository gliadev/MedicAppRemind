//
//  IntakeLogModel.swift
//  MedicAppRemind
//
//  F2.S1 — SwiftData persistence model for `IntakeLog`. CloudKit-safe.
//

import Foundation
import SwiftData

/// SwiftData record for a logged dose. The owning medication is held by the
/// optional `medication` relationship (its `id` becomes the domain
/// `medicationID`); `status` is persisted as its `rawValue` in `statusRaw`.
@Model
final class IntakeLogModel {
    var id: UUID = UUID()
    var scheduledAt: Date = Date.now
    var takenAt: Date?
    var statusRaw: String = DoseStatus.pending.rawValue
    var pillsTaken: Double = 0
    var medication: MedicationModel?

    init() {}
}
