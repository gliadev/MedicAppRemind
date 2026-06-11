//
//  ReminderBudgetTests.swift
//  MedicAppRemindTests
//
//  F3.S2 — iOS silently drops pending local notifications beyond 64 per app, so the
//  planner must truncate to the cap, nearest first. The truncation is pure and tested
//  here without touching `UNUserNotificationCenter`.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ReminderBudget")
struct ReminderBudgetTests {

    /// A medication whose id is derived from `index`, so identifiers are stable and never
    /// collide. Default stock lasts well beyond the threshold, keeping its low-stock alert
    /// far in the future (so dose reminders are always the nearest).
    private func medication(_ index: Int) -> Medication {
        let suffix = index.formatted(.number.grouping(.never).precision(.integerLength(12)))
        let id = UUID(uuidString: "0BADF00D-0000-0000-0000-\(suffix)") ?? UUID()
        return makeMedication(id: id, name: "Med\(index)", currentStock: 30, lowStockThresholdDays: 7)
    }

    /// A medication paired with a single once-daily 09:00 schedule.
    private func dailyPlan(_ index: Int) -> MedicationPlan {
        makePlan(medication(index), [makeSchedule(.daily, times: [DateComponents(hour: 9)])])
    }

    @Test("More candidate reminders than the cap are truncated to 64 unique requests")
    func capsAtSixtyFour() throws {
        let reference = try isoDate("2026-06-09T06:00:00Z")
        // 70 meds, each one daily dose + one low-stock alert → 140 candidate reminders.
        let plans = (1...70).map { dailyPlan($0) }
        let reminders = plannedReminders(for: plans, from: reference, calendar: try utcCalendar())
        #expect(reminders.count == 64)
        #expect(Set(reminders.map(\.identifier)).count == 64)
        // Every dose fires within the day; every low-stock is weeks out, so doses fill the cap.
        #expect(reminders.allSatisfy { $0.kind == .dose })
    }

    @Test("Within the cap, every candidate reminder is kept")
    func keepsAllUnderCap() throws {
        let reference = try isoDate("2026-06-09T06:00:00Z")
        let plans = (1...3).map { dailyPlan($0) }
        let reminders = plannedReminders(for: plans, from: reference, calendar: try utcCalendar())
        // 3 dose reminders + 3 low-stock reminders.
        #expect(reminders.count == 6)
        #expect(reminders.filter { $0.kind == .dose }.count == 3)
        #expect(reminders.filter { $0.kind == .lowStock }.count == 3)
    }

    @Test("Nearest reminders win the cap")
    func nearestFirstWinsTheCap() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T10:00:00Z")
        // med1 fires today at 20:00; med2 not until tomorrow at 08:00.
        let soon = makePlan(medication(1), [makeSchedule(.daily, times: [DateComponents(hour: 20)])])
        let later = makePlan(medication(2), [makeSchedule(.daily, times: [DateComponents(hour: 8)])])
        let reminders = plannedReminders(for: [later, soon], from: reference, calendar: calendar, limit: 1)
        let kept = try #require(reminders.first)
        #expect(reminders.count == 1)
        #expect(kept.medicationID == medication(1).id)
        #expect(kept.kind == .dose)
    }
}
