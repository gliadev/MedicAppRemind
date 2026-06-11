//
//  PersistenceTestSupport.swift
//  MedicAppRemindTests
//
//  F2 — Fixtures and helpers for the persistence test suite.
//  Containers are always in-memory; tests never touch CloudKit or disk.
//

import Foundation
import SwiftData
@testable import MedicAppRemind

/// Stable identifier for intake-log fixtures so two fixtures compare equal by value.
/// The literal is a valid UUID, so `?? UUID()` is an unreachable fallback that
/// merely satisfies the no-force-unwrap rule.
let intakeLogFixtureID = UUID(uuidString: "0BADF00D-0000-0000-0000-000000000002") ?? UUID()

/// Builds an `IntakeLog` whose `medicationID` defaults to `medicationFixtureID`,
/// so it lines up with the medication built by `makeMedication`.
func makeIntakeLog(
    id: UUID = intakeLogFixtureID,
    medicationID: UUID = medicationFixtureID,
    scheduledAt: Date = domainFixtureDate,
    takenAt: Date? = nil,
    status: DoseStatus = .pending,
    pillsTaken: Double = 0
) -> IntakeLog {
    IntakeLog(
        id: id,
        medicationID: medicationID,
        scheduledAt: scheduledAt,
        takenAt: takenAt,
        status: status,
        pillsTaken: pillsTaken
    )
}

/// Builds a fresh in-memory `ModelContainer` for the V1 schema.
///
/// `isStoredInMemoryOnly` keeps the store off disk and `cloudKitDatabase: .none`
/// keeps it off CloudKit, so each test runs against an isolated, ephemeral store.
func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema(versionedSchema: MedicineSchemaV1.self)
    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(for: schema, configurations: [configuration])
}

/// Inserts a medication with one schedule and one intake log, all wired by their
/// relationships, and saves. Returns the persisted `MedicationModel`.
@MainActor
func insertSampleGraph(
    into context: ModelContext,
    medication: Medication,
    schedule: DoseSchedule,
    log: IntakeLog
) throws -> MedicationModel {
    let medicationModel = MedicationModel()
    medicationModel.apply(medication)
    context.insert(medicationModel)

    let scheduleModel = DoseScheduleModel()
    try scheduleModel.apply(schedule)
    scheduleModel.medication = medicationModel
    context.insert(scheduleModel)

    let logModel = IntakeLogModel()
    logModel.apply(log)
    logModel.medication = medicationModel
    context.insert(logModel)

    try context.save()
    return medicationModel
}
