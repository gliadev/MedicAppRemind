//
//  DoseMathTests.swift
//  MedicAppRemindTests
//
//  F1.S2 — Clinical dose math. Every test fixes an input and asserts a
//  hand-computed output. Dates are injected; nothing reads the wall clock.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("DoseMath")
struct DoseMathTests {

    // MARK: - dosesPerDay

    @Test("Daily schedule yields one dose per listed time of day")
    func dailyDosesEqualTimeCount() {
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 9), DateComponents(hour: 21)])
        #expect(schedule.dosesPerDay == 2)
    }

    @Test("Every-8-hours schedule yields three doses per day")
    func everyEightHoursIsThreeDosesPerDay() {
        #expect(makeSchedule(.everyNHours(8)).dosesPerDay == 3)
    }

    @Test("Once daily every weekday averages one dose per day")
    func allWeekdaysOnceIsOnePerDay() {
        let schedule = makeSchedule(.weekdays(Weekday.allCases), times: [DateComponents(hour: 9)])
        #expect(schedule.dosesPerDay == 1)
    }

    @Test("Once daily three days a week averages 3/7 dose per day")
    func threeWeekdaysOnceAveragesThreeSevenths() {
        let schedule = makeSchedule(.weekdays([.monday, .wednesday, .friday]), times: [DateComponents(hour: 9)])
        #expect(abs(schedule.dosesPerDay - 0.4285714285714286) < 1e-12)
    }

    @Test("A schedule with no times of day never fires")
    func emptyTimesMeansZeroDoses() {
        #expect(makeSchedule(.daily, times: []).dosesPerDay == 0)
    }

    @Test("A non-positive hour interval never fires (no divide-by-zero)")
    func nonPositiveIntervalMeansZeroDoses() {
        #expect(makeSchedule(.everyNHours(0)).dosesPerDay == 0)
    }

    // MARK: - remainingDays

    @Test("Thirty pills, one per dose, once a day, last thirty days")
    func thirtyPillsOncePerDayLastThirtyDays() {
        let med = makeMedication(pillsPerDose: 1, currentStock: 30)
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 9)])
        #expect(med.remainingDays(for: schedule) == 30)
    }

    @Test("Two pills per dose halves the days of supply")
    func twoPillsPerDoseHalvesDays() {
        let med = makeMedication(pillsPerDose: 2, currentStock: 30)
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 9)])
        #expect(med.remainingDays(for: schedule) == 15)
    }

    @Test("Empty stock means zero remaining days")
    func zeroStockMeansZeroDays() {
        let med = makeMedication(currentStock: 0)
        #expect(med.remainingDays(for: makeSchedule(.daily, times: [DateComponents(hour: 9)])) == 0)
    }

    @Test("A schedule that never fires has undefined remaining days")
    func zeroDosesPerDayMeansNil() {
        let med = makeMedication(currentStock: 30)
        #expect(med.remainingDays(for: makeSchedule(.daily, times: [])) == nil)
    }

    @Test("Zero pills per dose returns nil instead of dividing by zero")
    func zeroPillsPerDoseMeansNil() {
        let med = makeMedication(pillsPerDose: 0, currentStock: 30)
        #expect(med.remainingDays(for: makeSchedule(.daily, times: [DateComponents(hour: 9)])) == nil)
    }

    // MARK: - refillDate

    @Test("Refill date is the base date plus the whole remaining days")
    func refillDateIsBasePlusRemainingDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let base = try Date("2026-06-09T08:00:00Z", strategy: .iso8601)
        let med = makeMedication(pillsPerDose: 1, currentStock: 30)
        let schedule = makeSchedule(.daily, times: [DateComponents(hour: 8)])
        // 2026-06-09 + 30 days = 2026-07-09, computed independently of the implementation.
        let expected = try Date("2026-07-09T08:00:00Z", strategy: .iso8601)
        #expect(med.refillDate(from: base, for: schedule, calendar: calendar) == expected)
    }

    @Test("Refill date is nil when the schedule never fires")
    func refillDateIsNilWithoutDoses() {
        let med = makeMedication(currentStock: 30)
        #expect(med.refillDate(from: domainFixtureDate, for: makeSchedule(.daily, times: [])) == nil)
    }

    // MARK: - isLowStock

    @Test("Five remaining days under a seven-day threshold is low stock")
    func fiveDaysUnderSevenThresholdIsLow() {
        let med = makeMedication(currentStock: 5, lowStockThresholdDays: 7)
        #expect(med.isLowStock(for: makeSchedule(.daily, times: [DateComponents(hour: 9)])))
    }

    @Test("Ten remaining days over a seven-day threshold is not low stock")
    func tenDaysOverSevenThresholdIsNotLow() {
        let med = makeMedication(currentStock: 10, lowStockThresholdDays: 7)
        #expect(!med.isLowStock(for: makeSchedule(.daily, times: [DateComponents(hour: 9)])))
    }

    @Test("Out of stock is low stock")
    func zeroStockIsLow() {
        let med = makeMedication(currentStock: 0, lowStockThresholdDays: 7)
        #expect(med.isLowStock(for: makeSchedule(.daily, times: [DateComponents(hour: 9)])))
    }

    @Test("A medication that is never consumed is not low stock")
    func noDosesIsNotLow() {
        let med = makeMedication(currentStock: 0, lowStockThresholdDays: 7)
        #expect(!med.isLowStock(for: makeSchedule(.daily, times: [])))
    }
}
