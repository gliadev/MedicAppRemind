//
//  RecordIntakeTests.swift
//  MedicAppRemindTests
//
//  F3.S3 — `recordIntake` logs a taken dose and decrements stock in one save,
//  idempotently by log id, so a double tap of the same notification never
//  double-logs or double-decrements. In-memory store only.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("RecordIntake")
struct RecordIntakeTests {

    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("Recording the same dose id twice logs and decrements only once")
    func idempotentByLogID() async throws {
        let store = try makeStore()
        // 10 in stock, 2 per dose → one intake leaves 8; a duplicate must not reach 6.
        try await store.upsert(makeMedication(pillsPerDose: 2, currentStock: 10))
        let log = makeIntakeLog(
            id: intakeLogFixtureID,
            takenAt: domainFixtureDate,
            status: .taken,
            pillsTaken: 2
        )

        let first = try await store.recordIntake(log, decrementingStockBy: 2)
        let second = try await store.recordIntake(log, decrementingStockBy: 2)

        #expect(first == true)
        #expect(second == false)
        #expect(try await store.fetchAll().first?.currentStock == 8)
    }

    @Test("Recording an intake for an unknown medication throws an orphan error")
    func unknownMedicationThrows() async throws {
        let store = try makeStore()
        await #expect(throws: PersistenceError.orphanIntakeLog) {
            _ = try await store.recordIntake(
                makeIntakeLog(status: .taken, pillsTaken: 1),
                decrementingStockBy: 1
            )
        }
    }
}
