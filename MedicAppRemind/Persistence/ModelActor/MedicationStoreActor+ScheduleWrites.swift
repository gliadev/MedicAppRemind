//
//  MedicationStoreActor+ScheduleWrites.swift
//  MedicAppRemind
//
//  F5.S2 — Schedule writes for the App Intents layer. `ScheduleReminderIntent`
//  adds a time of day to a medication's dosing schedule; this is the off-main,
//  serialized persistence path for that, returning a domain `MedicationPlan` so the
//  caller can reprogram reminders without any `@Model` crossing the actor boundary.
//

import Foundation
import SwiftData

extension MedicationStoreActor {
    /// Adds a time of day to the medication's schedule and returns the updated plan.
    ///
    /// Appends to the medication's first schedule, or creates a once-daily schedule
    /// when it has none. Idempotent: a time already present is not duplicated.
    /// Returns `nil` when the medication is unknown.
    func addDoseTime(_ time: DateComponents, toMedication id: UUID) throws -> MedicationPlan? {
        var descriptor = FetchDescriptor<MedicationModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        guard let model = try modelContext.fetch(descriptor).first else { return nil }

        let scheduleModel: DoseScheduleModel
        var schedule: DoseSchedule
        if let existing = model.schedules?.first {
            scheduleModel = existing
            schedule = try existing.toDomain()
        } else {
            scheduleModel = DoseScheduleModel()
            scheduleModel.medication = model
            modelContext.insert(scheduleModel)
            schedule = DoseSchedule(times: [], frequency: .daily, startDate: .now, endDate: nil)
        }

        if !schedule.times.contains(time) {
            schedule.times.append(time)
        }
        try scheduleModel.apply(schedule)
        model.updatedAt = .now
        try modelContext.save()

        let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
        return MedicationPlan(medication: model.toDomain(), schedules: schedules)
    }
}
