//
//  QueryRemainingTests.swift
//  MedicAppRemindTests
//
//  F5.S2 — The testable core of `QueryRemainingIntent`. The dialog text and the
//  snippet view are thin formats over `remainingSupply`, whose day count comes
//  straight from `DoseMath` (`Medication.remainingDays(for:)`). No clinical math
//  lives in the intent.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("QueryRemaining supply")
struct QueryRemainingTests {

    @Test("Remaining supply reports the DoseMath day count and the current pills")
    func remainingSupplyReportsDaysAndPills() {
        // 10 pills, 2 per dose, once daily → 1 dose/day → 10 / (2 × 1) = 5 days.
        let plan = MedicationPlan(
            medication: makeMedication(pillsPerDose: 2, currentStock: 10),
            schedules: [makeSchedule()]
        )

        let supply = remainingSupply(for: plan)

        #expect(supply.medicationName == "Ibuprofeno")
        #expect(supply.remainingPills == 10)
        #expect(supply.remainingDays == 5)
    }

    @Test("With several schedules the soonest (most conservative) depletion wins")
    func remainingSupplyTakesSoonestDepletion() {
        // Two daily schedules consume the same stock; the planner reports the
        // shortest estimate (twice-daily → 5 days), never the rosier once-daily one.
        let onceDaily = makeSchedule(.daily, times: [DateComponents(hour: 9)])
        let twiceDaily = makeSchedule(.daily, times: [DateComponents(hour: 9), DateComponents(hour: 21)])
        let plan = MedicationPlan(
            medication: makeMedication(pillsPerDose: 1, currentStock: 10),
            schedules: [onceDaily, twiceDaily]
        )

        let supply = remainingSupply(for: plan)

        // twiceDaily: 10 / (1 × 2) = 5 days; onceDaily would be 10 — min wins.
        #expect(supply.remainingDays == 5)
    }

    @Test("A medication with no consuming schedule has no day estimate")
    func remainingSupplyNoScheduleIsNil() {
        let plan = MedicationPlan(medication: makeMedication(currentStock: 10), schedules: [])

        let supply = remainingSupply(for: plan)

        #expect(supply.remainingDays == nil)
        #expect(supply.remainingPills == 10)
    }
}
