//
//  MedicationStoreActor.swift
//  MedicAppRemind
//
//  F2.S2 — All writes go through this actor, off the main thread. It never lets
//  a `ModelContext` or `@Model` cross its boundary: callers pass domain value
//  types and `UUID`s in, and receive domain value types out.
//

import Foundation
import SwiftData

/// Serialized, off-main access to the persistence store. Identity is logical
/// (`Medication.id`), deduplicated here rather than with `@Attribute(.unique)`,
/// which CloudKit forbids.
@ModelActor
actor MedicationStoreActor {

    /// All medications, sorted by name, projected to domain values.
    func fetchAll() throws -> [Medication] {
        let descriptor = FetchDescriptor<MedicationModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    /// Inserts the medication, or updates the existing record with the same `id`.
    /// Idempotent by `id`: a second call with the same id never creates a duplicate.
    func upsert(_ medication: Medication) throws {
        let model = try existingMedication(id: medication.id) ?? insertedMedication()
        model.apply(medication)
        try modelContext.save()
    }

    /// Deletes the medication with the given `id` (cascading to its schedules and
    /// logs). A missing id is a no-op.
    func delete(id: UUID) throws {
        guard let model = try existingMedication(id: id) else { return }
        modelContext.delete(model)
        try modelContext.save()
    }

    /// Records a logged dose against its medication.
    /// Throws `PersistenceError.orphanIntakeLog` when the medication is unknown.
    func appendIntakeLog(_ log: IntakeLog) throws {
        guard let medication = try existingMedication(id: log.medicationID) else {
            throw PersistenceError.orphanIntakeLog
        }
        let model = IntakeLogModel()
        model.apply(log)
        model.medication = medication
        modelContext.insert(model)
        try modelContext.save()
    }

    /// Subtracts `pills` from the medication's stock, clamped at zero (stock is
    /// never negative). A missing id is a no-op.
    func decrementStock(medicationID: UUID, by pills: Double) throws {
        guard let model = try existingMedication(id: medicationID) else { return }
        model.currentStock = max(0, model.currentStock - pills)
        model.updatedAt = .now
        try modelContext.save()
    }

    /// Records a confirmed dose: appends the log and subtracts stock in one save,
    /// idempotently. Returns `false` without writing when a log with the same `id`
    /// already exists, so re-handling the same notification (a double tap) never
    /// double-logs or double-decrements. Returns `true` when the intake was new.
    ///
    /// Throws `PersistenceError.orphanIntakeLog` when the medication is unknown.
    func recordIntake(_ log: IntakeLog, decrementingStockBy pills: Double) throws -> Bool {
        guard try existingIntakeLog(id: log.id) == nil else { return false }
        guard let medication = try existingMedication(id: log.medicationID) else {
            throw PersistenceError.orphanIntakeLog
        }
        let model = IntakeLogModel()
        model.apply(log)
        model.medication = medication
        modelContext.insert(model)
        medication.currentStock = max(0, medication.currentStock - pills)
        medication.updatedAt = .now
        try modelContext.save()
        return true
    }

    /// Every medication paired with its decoded schedules — the reminder planner's
    /// input. A schedule whose stored payload is corrupted is skipped rather than
    /// failing the whole refresh.
    func fetchPlans() throws -> [MedicationPlan] {
        let descriptor = FetchDescriptor<MedicationModel>(sortBy: [SortDescriptor(\.name)])
        return try modelContext.fetch(descriptor).map { model in
            let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
            return MedicationPlan(medication: model.toDomain(), schedules: schedules)
        }
    }

    /// The medication with this `id`, projected to its domain value, or `nil` if
    /// none exists.
    func medication(id: UUID) throws -> Medication? {
        try existingMedication(id: id)?.toDomain()
    }

    /// The medication with this `id` paired with its decoded schedules — the input
    /// CalendarSyncService needs to build calendar events. A schedule whose stored
    /// payload is corrupted is skipped. `nil` when the medication is unknown.
    func plan(id: UUID) throws -> MedicationPlan? {
        guard let model = try existingMedication(id: id) else { return nil }
        let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
        return MedicationPlan(medication: model.toDomain(), schedules: schedules)
    }

    /// The calendar `eventIdentifier`s currently mirrored for this medication (F4.S2),
    /// or `[]` when it isn't mirrored or the medication is unknown.
    func calendarEventIDs(medicationID: UUID) throws -> [String] {
        try existingMedication(id: medicationID)?.calendarEventIDs ?? []
    }

    /// Records the calendar `eventIdentifier`s now mirrored for this medication,
    /// replacing any previous set. An empty array clears the field. A missing id is a
    /// no-op.
    func setCalendarEventIDs(_ identifiers: [String], medicationID: UUID) throws {
        guard let model = try existingMedication(id: medicationID) else { return }
        model.calendarEventIDs = identifiers
        model.updatedAt = .now
        try modelContext.save()
    }

    // MARK: - Helpers

    private func existingMedication(id: UUID) throws -> MedicationModel? {
        var descriptor = FetchDescriptor<MedicationModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func existingIntakeLog(id: UUID) throws -> IntakeLogModel? {
        var descriptor = FetchDescriptor<IntakeLogModel>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func insertedMedication() -> MedicationModel {
        let model = MedicationModel()
        modelContext.insert(model)
        return model
    }
}
