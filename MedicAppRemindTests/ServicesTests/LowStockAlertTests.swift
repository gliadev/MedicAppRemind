//
//  LowStockAlertTests.swift
//  MedicAppRemindTests
//
//  F3.S2 — The low-stock alert date is pure dose math derived from `refillDate`
//  (the single clinical formula). Every test fixes an input and asserts a
//  hand-computed date with an injected UTC calendar.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("LowStockAlert")
struct LowStockAlertTests {

    /// A once-daily 09:00 schedule, so consumption is exactly one dose per day.
    private let dailySchedule = makeSchedule(.daily, times: [DateComponents(hour: 9)])

    @Test("Stock lasting 10 days with a 7-day threshold alerts on day 3")
    func alertsThreeDaysIn() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T09:00:00Z")
        // 10 pills, 1 per dose, once daily → 10 days of supply; crosses the 7-day
        // threshold 3 days from now (10 − 7).
        let med = makeMedication(currentStock: 10, lowStockThresholdDays: 7)
        let alert = try #require(med.lowStockAlertDate(from: reference, for: dailySchedule, calendar: calendar))
        let expected = try #require(calendar.date(byAdding: .day, value: 3, to: reference))
        #expect(alert == expected)
    }

    @Test("Stock already below the threshold alerts today")
    func alertsTodayWhenAlreadyLow() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T09:00:00Z")
        // 5 days of supply, threshold 7 → already below; the date is clamped to today.
        let med = makeMedication(currentStock: 5, lowStockThresholdDays: 7)
        let alert = try #require(med.lowStockAlertDate(from: reference, for: dailySchedule, calendar: calendar))
        #expect(alert == reference)
    }

    @Test("Supply exactly at the threshold alerts today")
    func alertsTodayAtThreshold() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T09:00:00Z")
        // 7 days of supply, threshold 7 → crossing is today.
        let med = makeMedication(currentStock: 7, lowStockThresholdDays: 7)
        let alert = try #require(med.lowStockAlertDate(from: reference, for: dailySchedule, calendar: calendar))
        #expect(alert == reference)
    }

    @Test("An undefined consumption rate yields no alert date")
    func noAlertWhenRateUndefined() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T09:00:00Z")
        // pillsPerDose 0 → remainingDays undefined → a never-consumed med can't run low.
        let med = makeMedication(pillsPerDose: 0, currentStock: 10)
        #expect(med.lowStockAlertDate(from: reference, for: dailySchedule, calendar: calendar) == nil)
    }
}
