//
//  CalendarSyncReducerTests.swift
//  MedicAppRemindTests
//
//  F4.S2 — The pure decision behind calendar reconciliation. Given the identifiers
//  already mirrored to the calendar and a user/system intent, the reducer decides
//  which events to remove and whether to create fresh ones. No EventKit, no store:
//  each test fixes an input and asserts a hand-computed plan.
//

import Testing
@testable import MedicAppRemind

@Suite("CalendarSyncReducer")
struct CalendarSyncReducerTests {

    @Test("Enabling with no stored events creates events and removes nothing")
    func enableFromClean() {
        let plan = CalendarSyncIntent.enable.reconcile(against: [])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: [], createsEvents: true))
    }

    @Test("Enabling clears any stale stored events before recreating")
    func enableClearsStale() {
        let plan = CalendarSyncIntent.enable.reconcile(against: ["a", "b"])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: ["a", "b"], createsEvents: true))
    }

    @Test("Disabling removes every stored event and creates none")
    func disableRemovesAll() {
        let plan = CalendarSyncIntent.disable.reconcile(against: ["a", "b"])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: ["a", "b"], createsEvents: false))
    }

    @Test("Disabling when nothing is stored is a clean no-op")
    func disableWhenEmpty() {
        let plan = CalendarSyncIntent.disable.reconcile(against: [])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: [], createsEvents: false))
    }

    @Test("A schedule change while synced replaces all events")
    func scheduleChangedWhileSynced() {
        let plan = CalendarSyncIntent.scheduleChanged.reconcile(against: ["a"])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: ["a"], createsEvents: true))
    }

    @Test("A schedule change while not synced does nothing")
    func scheduleChangedWhileNotSynced() {
        let plan = CalendarSyncIntent.scheduleChanged.reconcile(against: [])
        #expect(plan == CalendarSyncPlan(identifiersToRemove: [], createsEvents: false))
    }
}
