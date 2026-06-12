//
//  ScheduleReminderWriteTests.swift
//  MedicAppRemindTests
//
//  F5.S2 — The persistence write behind `ScheduleReminderIntent`: adding a dose
//  time to a medication's schedule. The intent itself is a thin wrapper that maps
//  a `Date` to hour/minute components, calls this, then reprograms reminders.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("ScheduleReminder dose-time writes")
struct ScheduleReminderWriteTests {

    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("Adding a time to a medication with no schedule creates a daily schedule")
    func addsTimeCreatingSchedule() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())

        let plan = try #require(
            try await store.addDoseTime(DateComponents(hour: 20, minute: 0), toMedication: medicationFixtureID)
        )

        #expect(plan.schedules.count == 1)
        #expect(plan.schedules.first?.frequency == .daily)
        #expect(plan.schedules.first?.times == [DateComponents(hour: 20, minute: 0)])
    }

    @Test("Adding more times appends in order and never duplicates")
    func appendsWithoutDuplicates() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())

        _ = try await store.addDoseTime(DateComponents(hour: 20, minute: 0), toMedication: medicationFixtureID)
        _ = try await store.addDoseTime(DateComponents(hour: 9, minute: 0), toMedication: medicationFixtureID)
        let plan = try #require(
            // The repeat of 20:00 must not add a second entry.
            try await store.addDoseTime(DateComponents(hour: 20, minute: 0), toMedication: medicationFixtureID)
        )

        #expect(plan.schedules.first?.times == [DateComponents(hour: 20, minute: 0), DateComponents(hour: 9, minute: 0)])
    }

    @Test("Adding a time to an unknown medication returns nil")
    func unknownMedicationReturnsNil() async throws {
        let store = try makeStore()

        #expect(try await store.addDoseTime(DateComponents(hour: 20), toMedication: UUID()) == nil)
    }
}
