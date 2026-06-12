//
//  CalendarEventIDsPersistenceTests.swift
//  MedicAppRemindTests
//
//  F4.S2 — The store persists the calendar event identifiers mirrored for a medication
//  so they survive across sessions and can be removed without orphans. Round-trips
//  through the actor on an in-memory store; never touches EventKit, CloudKit or disk.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("CalendarEventIDsPersistence")
struct CalendarEventIDsPersistenceTests {

    private func makeStore() throws -> MedicationStoreActor {
        let controller = try PersistenceController(inMemory: true)
        return MedicationStoreActor(modelContainer: controller.container)
    }

    @Test("A fresh medication mirrors no calendar events")
    func defaultsToEmpty() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())
        #expect(try await store.calendarEventIDs(medicationID: medicationFixtureID).isEmpty)
    }

    @Test("Stored identifiers survive a fetch in order")
    func roundTrip() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())

        try await store.setCalendarEventIDs(["evt-1", "evt-2", "evt-3"], medicationID: medicationFixtureID)

        #expect(try await store.calendarEventIDs(medicationID: medicationFixtureID) == ["evt-1", "evt-2", "evt-3"])
    }

    @Test("Setting an empty array clears the stored identifiers")
    func clearing() async throws {
        let store = try makeStore()
        try await store.upsert(makeMedication())
        try await store.setCalendarEventIDs(["evt-1"], medicationID: medicationFixtureID)

        try await store.setCalendarEventIDs([], medicationID: medicationFixtureID)

        #expect(try await store.calendarEventIDs(medicationID: medicationFixtureID).isEmpty)
    }

    @Test("Unknown medication reads as empty and ignores writes")
    func unknownMedicationIsNoOp() async throws {
        let store = try makeStore()
        let stranger = try #require(UUID(uuidString: "0BADF00D-0000-0000-0000-0000000000FF"))

        try await store.setCalendarEventIDs(["evt-1"], medicationID: stranger)

        #expect(try await store.calendarEventIDs(medicationID: stranger).isEmpty)
    }
}
