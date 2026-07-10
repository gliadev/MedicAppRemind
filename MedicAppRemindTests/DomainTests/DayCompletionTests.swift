//
//  DayCompletionTests.swift
//  MedicAppRemindTests
//
//  Pins the pure rule that drives the "all doses taken" celebration on TodayView:
//  a day is complete only when it has at least one dose and every one is taken.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Day completion")
struct DayCompletionTests {

    private func slot(taken: Bool) -> DoseSlot {
        DoseSlot(
            id: UUID(),
            medicationID: UUID(),
            medicationName: "Test",
            doseLabel: "1 mg",
            pillsPerDose: 1,
            scheduledAt: .now,
            period: .morning,
            isTaken: taken
        )
    }

    @Test("An empty day is never complete")
    func emptyDayNotComplete() {
        #expect([DoseSlot]().isDayComplete == false)
    }

    @Test("A day with every dose taken is complete")
    func allTakenComplete() {
        let slots = [slot(taken: true), slot(taken: true), slot(taken: true)]
        #expect(slots.isDayComplete == true)
    }

    @Test("A day with any pending dose is not complete")
    func anyPendingNotComplete() {
        let slots = [slot(taken: true), slot(taken: false), slot(taken: true)]
        #expect(slots.isDayComplete == false)
    }

    @Test("A single taken dose completes the day")
    func singleTakenComplete() {
        #expect([slot(taken: true)].isDayComplete == true)
    }
}
