//
//  MedicationStoreActor+EditorWrites.swift
//  MedicAppRemind
//
//  F6.S3 — Upserts a medication together with its primary schedule in a single
//  save. Used by MedicationEditorView when the user taps "Guardar".
//

import Foundation
import SwiftData

extension MedicationStoreActor {
    /// Upserts a medication and replaces (or creates) its primary schedule atomically.
    ///
    /// Idempotent by medication `id`. A second call with the same id updates the
    /// existing record; it never creates a duplicate. Extra schedules beyond the
    /// first are left untouched so that `addDoseTime` (F5.S2) data is not lost.
    func upsert(_ medication: Medication, schedule: DoseSchedule) throws {
        var medDescriptor = FetchDescriptor<MedicationModel>(
            predicate: #Predicate { $0.id == medication.id }
        )
        medDescriptor.fetchLimit = 1
        let medModel: MedicationModel
        if let existing = try modelContext.fetch(medDescriptor).first {
            medModel = existing
        } else {
            medModel = MedicationModel()
            modelContext.insert(medModel)
        }
        medModel.apply(medication)

        let scheduleModel: DoseScheduleModel
        if let existing = medModel.schedules?.first {
            scheduleModel = existing
        } else {
            scheduleModel = DoseScheduleModel()
            scheduleModel.medication = medModel
            modelContext.insert(scheduleModel)
        }
        try scheduleModel.apply(schedule)
        try modelContext.save()
    }
}
