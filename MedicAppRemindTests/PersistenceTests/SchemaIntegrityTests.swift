//
//  SchemaIntegrityTests.swift
//  MedicAppRemindTests
//
//  F2.S1 — The CloudKit-safe schema persists, maps back to domain, and
//  cascades deletes. In-memory store only; no CloudKit, no disk.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@MainActor
@Suite("Schema integrity")
struct SchemaIntegrityTests {

    @Test("A persisted medication graph reads back equal to its domain values")
    func graphRoundTripsToDomain() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let medication = makeMedication(notes: "Con las comidas", currentStock: 42)
        let schedule = makeSchedule(.everyNHours(8))
        let log = makeIntakeLog(takenAt: domainFixtureDate, status: .taken, pillsTaken: 1)

        _ = try insertSampleGraph(into: context, medication: medication, schedule: schedule, log: log)

        let fetched = try #require(try context.fetch(FetchDescriptor<MedicationModel>()).first)
        #expect(fetched.toDomain() == medication)

        let fetchedSchedule = try #require(fetched.schedules?.first)
        #expect(try fetchedSchedule.toDomain() == schedule)

        let fetchedLog = try #require(fetched.intakeLogs?.first)
        #expect(try fetchedLog.toDomain() == log)
    }

    @Test("Deleting a medication cascades to its schedules and intake logs")
    func deleteCascadesToChildren() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let medicationModel = try insertSampleGraph(
            into: context,
            medication: makeMedication(),
            schedule: makeSchedule(),
            log: makeIntakeLog()
        )

        context.delete(medicationModel)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<MedicationModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<DoseScheduleModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<IntakeLogModel>()) == 0)
    }

    @Test("everyNHours(8) survives a round-trip through frequencyData")
    func frequencyRoundTripsThroughData() throws {
        let scheduleModel = DoseScheduleModel()
        try scheduleModel.apply(makeSchedule(.everyNHours(8)))

        let frequencyData = try #require(scheduleModel.frequencyData)
        #expect(!frequencyData.isEmpty)
        #expect(try scheduleModel.toDomain().frequency == .everyNHours(8))
    }
}
