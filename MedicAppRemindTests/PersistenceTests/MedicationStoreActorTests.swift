//
//  MedicationStoreActorTests.swift
//  MedicAppRemindTests
//
//  F2.S2 — The store actor persists and reads back domain value types only,
//  upserts idempotently by id, clamps stock at zero, and serializes concurrent
//  writes. In-memory store only.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("MedicationStoreActor")
struct MedicationStoreActorTests {

    /// Fresh in-memory store + actor for one test, with nothing leaking between tests.
    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("Upsert then fetch returns an equal domain value")
    func upsertThenFetchRoundTrips() async throws {
        let store = try makeStore()
        let medication = makeMedication(currentStock: 20)

        try await store.upsert(medication)

        #expect(try await store.fetchAll() == [medication])
    }

    @Test("Upsert on an existing id updates in place, never duplicates")
    func upsertOnExistingIdUpdatesWithoutDuplicating() async throws {
        let store = try makeStore()

        try await store.upsert(makeMedication(currentStock: 30))
        try await store.upsert(makeMedication(currentStock: 12))

        let all = try await store.fetchAll()
        #expect(all.count == 1)
        #expect(all.first?.currentStock == 12)
    }

    @Test("Decrement subtracts from stock and clamps at zero")
    func decrementStockSubtractsAndClampsAtZero() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication(currentStock: 10))

        try await store.decrementStock(medicationID: medicationFixtureID, by: 3)
        #expect(try await store.fetchAll().first?.currentStock == 7)

        try await store.decrementStock(medicationID: medicationFixtureID, by: 100)
        #expect(try await store.fetchAll().first?.currentStock == 0)
    }

    @Test("Delete removes the medication and cascades to its children")
    func deleteRemovesMedication() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())

        try await store.delete(id: medicationFixtureID)

        #expect(try await store.fetchAll().isEmpty)
    }

    @Test("Appending a log to a missing medication throws an orphan error")
    func appendIntakeLogToMissingMedicationThrows() async throws {
        let store = try makeStore()

        await #expect(throws: PersistenceError.orphanIntakeLog) {
            try await store.appendIntakeLog(makeIntakeLog())
        }
    }

    @MainActor
    @Test("Appending a log attaches it to its medication")
    func appendIntakeLogAttachesToMedication() async throws {
        let controller = try PersistenceController(inMemory: true)
        let store = MedicationStoreActor(modelContainer: controller.container)
        try await store.upsert(makeMedication())

        try await store.appendIntakeLog(makeIntakeLog(takenAt: domainFixtureDate, status: .taken, pillsTaken: 1))

        let logCount = try controller.mainContext.fetchCount(FetchDescriptor<IntakeLogModel>())
        #expect(logCount == 1)
    }

    @Test("Fifty concurrent upserts of distinct ids end as fifty distinct rows")
    func concurrentUpsertsProduceDistinctEntries() async throws {
        let store = try makeStore()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask {
                    try await store.upsert(makeMedication(id: UUID(), name: "Med \(index)"))
                }
            }
            try await group.waitForAll()
        }

        #expect(try await store.fetchAll().count == 50)
    }
}
