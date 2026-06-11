//
//  DoseScheduleModel.swift
//  MedicAppRemind
//
//  F2.S1 — SwiftData persistence model for `DoseSchedule`. CloudKit-safe.
//

import Foundation
import SwiftData

/// SwiftData record for a dose schedule. The value-typed `DoseFrequency` and the
/// `[DateComponents]` times are persisted as encoded `Data` (`frequencyData`,
/// `timesData`) rather than as separate columns, keeping the relational shape flat
/// and CloudKit-safe. The inverse of `medication` lives on `MedicationModel`.
@Model
final class DoseScheduleModel {
    var id: UUID = UUID()
    var frequencyData: Data?
    var timesData: Data?
    var startDate: Date = Date.now
    var endDate: Date?
    var medication: MedicationModel?

    init() {}
}
