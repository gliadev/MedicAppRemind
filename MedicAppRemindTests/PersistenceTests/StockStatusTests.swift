//
//  StockStatusTests.swift
//  MedicAppRemindTests
//
//  F2.S3 — Smoke test for the badge computation: a persisted model maps to
//  domain and DoseMath yields the expected level and remaining days.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("StockStatus")
struct StockStatusTests {

    @Test("A mapped model with a once-daily schedule reports its days and OK level")
    func okStatusFromMappedModel() {
        let model = MedicationModel()
        model.apply(makeMedication(currentStock: 30))   // 30 pills, 1 per dose

        let status = model.toDomain().stockStatus(for: [makeSchedule()])   // 1 dose/day

        #expect(status == StockStatus(level: .ok, remainingDays: 30))
    }

    @Test("Supply at or below the threshold reports low")
    func lowStatusAtThreshold() {
        let medication = makeMedication(currentStock: 5, lowStockThresholdDays: 7)

        let status = medication.stockStatus(for: [makeSchedule()])

        #expect(status == StockStatus(level: .low, remainingDays: 5))
    }

    @Test("Out of stock reports critical with zero days")
    func criticalWhenOutOfStock() {
        let medication = makeMedication(currentStock: 0)

        let status = medication.stockStatus(for: [makeSchedule()])

        #expect(status == StockStatus(level: .critical, remainingDays: 0))
    }

    @Test("A medication with no consuming schedule is unknown")
    func unknownWithoutSchedules() {
        let status = makeMedication().stockStatus(for: [])

        #expect(status == StockStatus(level: .unknown, remainingDays: nil))
    }
}
