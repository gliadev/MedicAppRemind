//
//  ScanMergePersistenceTests.swift
//  MedicAppRemindTests
//
//  FX.S4 — The store persists the new scanning fields (expiry, national code, scanned
//  serials) and merges a scanned box idempotently by serial. Round-trips through the
//  actor on an in-memory store; never touches CloudKit or disk.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ScanMergePersistence")
struct ScanMergePersistenceTests {

    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("Expiry and national code survive an upsert round-trip")
    func scalarFieldsRoundTrip() async throws {
        let store = try makeStore()
        let expiry = try isoDate("2028-03-31T00:00:00Z")
        try await store.upsert(makeMedication(expiryDate: expiry, nationalCode: "681957"))

        let fetched = try #require(try await store.medication(id: medicationFixtureID))
        #expect(fetched.expiryDate == expiry)
        #expect(fetched.nationalCode == "681957")
    }

    @Test("Merging a scanned box adds its units and records its serial")
    func mergeAddsStockAndSerial() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication(currentStock: 5, nationalCode: "681957"))

        let box = ScannedBox(nationalCode: "681957", serial: "SN-1", units: 20, expiry: nil)
        let decision = try await store.applyScanMerge(box)

        #expect(decision == .addStock(units: 20))
        let med = try #require(try await store.medication(id: medicationFixtureID))
        #expect(med.currentStock == 25)
        #expect(try await store.scannedSerials(medicationID: medicationFixtureID) == ["SN-1"])
    }

    @Test("Re-merging the same serial is a no-op — idempotent by serial")
    func mergeIsIdempotentBySerial() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication(currentStock: 5, nationalCode: "681957"))
        let box = ScannedBox(nationalCode: "681957", serial: "SN-1", units: 20, expiry: nil)

        _ = try await store.applyScanMerge(box)
        let secondDecision = try await store.applyScanMerge(box)

        #expect(secondDecision == .duplicateBox)
        let med = try #require(try await store.medication(id: medicationFixtureID))
        #expect(med.currentStock == 25) // added once, not twice
        #expect(try await store.scannedSerials(medicationID: medicationFixtureID) == ["SN-1"])
    }

    @Test("Merging pulls the stored expiry to the nearer scanned date")
    func mergePullsExpiryNearer() async throws {
        let store = try makeStore()
        let stored = try isoDate("2029-01-31T00:00:00Z")
        let sooner = try isoDate("2027-10-31T00:00:00Z")
        try await store.upsert(makeMedication(expiryDate: stored, nationalCode: "681957"))

        _ = try await store.applyScanMerge(ScannedBox(nationalCode: "681957", serial: "SN-1", units: 10, expiry: sooner))

        let med = try #require(try await store.medication(id: medicationFixtureID))
        #expect(med.expiryDate == sooner)
    }

    @Test("An unknown national code decides to create without writing")
    func unknownCodeCreatesWithoutWriting() async throws {
        let store = try makeStore()
        let stranger = ScannedBox(nationalCode: "999999", serial: "SN-9", units: 30, expiry: nil)

        let decision = try await store.applyScanMerge(stranger)

        #expect(decision == .create(units: 30))
        #expect(try await store.fetchAll().isEmpty)
    }
}
