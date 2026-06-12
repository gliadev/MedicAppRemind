//
//  LogDoseIntentLogicTests.swift
//  MedicAppRemindTests
//
//  F5.S2 — The testable core of `LogDoseIntent`. The intent's `perform()` is a
//  thin wrapper over `logDose`, which reuses the F3 `recordedDose` reducer and the
//  store's idempotent `recordIntake`. The last test is the dual-container guard:
//  a dose logged through the actor must be visible to the main context the UI's
//  `@Query` reads — one shared container, no stale read.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("LogDoseIntent logic")
struct LogDoseIntentLogicTests {

    /// Fresh in-memory store + actor for one test, with nothing leaking between tests.
    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("Logging a dose records it taken and decrements stock by pillsPerDose")
    func logDoseRecordsAndDecrements() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication(pillsPerDose: 2, currentStock: 10))

        let outcome = try await logDose(medicationID: medicationFixtureID, using: store, at: domainFixtureDate)

        #expect(outcome.medicationName == "Ibuprofeno")
        #expect(outcome.remainingPills == 8)
        // The decrement is persisted, not merely computed for the dialog.
        #expect(try await store.medication(id: medicationFixtureID)?.currentStock == 8)
    }

    @Test("Logging the same occurrence twice decrements only once")
    func logDoseIsIdempotentByOccurrence() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication(pillsPerDose: 2, currentStock: 10))

        _ = try await logDose(medicationID: medicationFixtureID, using: store, at: domainFixtureDate)
        let second = try await logDose(medicationID: medicationFixtureID, using: store, at: domainFixtureDate)

        // Same medication + same instant → same occurrence id → one decrement.
        #expect(second.remainingPills == 8)
    }

    @Test("Logging an unknown medication throws")
    func logDoseUnknownThrows() async throws {
        let store = try makeStore()

        await #expect(throws: IntentError.medicationNotFound) {
            _ = try await logDose(medicationID: UUID(), using: store, at: domainFixtureDate)
        }
    }

    /// The dual-container guard. The App Intents runtime writes through a
    /// `MedicationStoreActor` over the *shared* container; the UI reads the same
    /// container's `mainContext` via `@Query`. This proves a dose logged on the
    /// intent path is visible to that main context — one container, no stale read.
    /// (A second, separate container would fail this: an in-memory store is private
    /// to its container, so the main-context re-read would still see 10.)
    @MainActor
    @Test("A dose logged through the actor is visible to the main context @Query reads")
    func loggedDoseReflectsInMainContext() async throws {
        let controller = try PersistenceController(inMemory: true)
        let container = controller.container
        let store = MedicationStoreActor(modelContainer: container)
        try await store.upsert(makeMedication(pillsPerDose: 2, currentStock: 10))

        // Prime the main context the way a live @Query does.
        let primed = try #require(try container.mainContext.fetch(FetchDescriptor<MedicationModel>()).first)
        #expect(primed.currentStock == 10)

        _ = try await logDose(medicationID: medicationFixtureID, using: store, at: domainFixtureDate)

        // What @Query re-reads on change must reflect the decrement.
        let reread = try #require(try container.mainContext.fetch(FetchDescriptor<MedicationModel>()).first)
        #expect(reread.currentStock == 8)
    }
}
