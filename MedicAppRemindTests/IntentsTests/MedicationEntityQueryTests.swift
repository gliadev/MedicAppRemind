//
//  MedicationEntityQueryTests.swift
//  MedicAppRemindTests
//
//  F5.S1 — The entity query resolves `MedicationEntity` values from the real
//  persistence layer (an in-memory `MedicationStoreActor`), never touching
//  CloudKit or disk. `entities(for:)` returns the matching records;
//  `suggestedEntities()` lists them all.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("MedicationEntityQuery")
struct MedicationEntityQueryTests {

    /// Fresh in-memory store + actor for one test, with nothing leaking between tests.
    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("entities(for:) resolves only the requested ids, as entities")
    func entitiesForIDsResolvesRequestedMatches() async throws {
        let store = try makeStore()
        let ibuprofeno = makeMedication(id: UUID(), name: "Ibuprofeno", doseLabel: "600 mg")
        let metformina = makeMedication(id: UUID(), name: "Metformina", doseLabel: "850 mg")
        try await store.upsert(ibuprofeno)
        try await store.upsert(metformina)
        let query = MedicationEntityQuery(store: store)

        let entities = try await query.entities(for: [metformina.id])

        #expect(entities == [MedicationEntity(metformina)])
    }

    @Test("suggestedEntities() lists every stored medication, name-sorted")
    func suggestedEntitiesListsAll() async throws {
        let store = try makeStore()
        let ibuprofeno = makeMedication(id: UUID(), name: "Ibuprofeno", doseLabel: "600 mg")
        let metformina = makeMedication(id: UUID(), name: "Metformina", doseLabel: "850 mg")
        try await store.upsert(metformina)
        try await store.upsert(ibuprofeno)
        let query = MedicationEntityQuery(store: store)

        let suggested = try await query.suggestedEntities()

        // The store sorts by name, so "Ibuprofeno" precedes "Metformina".
        #expect(suggested == [MedicationEntity(ibuprofeno), MedicationEntity(metformina)])
    }
}
