//
//  ExpiryPlannerTests.swift
//  MedicAppRemindTests
//
//  FX.S4 — The expiry alert dates are pure calendar math (the "decision"): a heads-up
//  `expiryWarningLeadDays` before expiry and one on the expiry day, each clamped to today
//  when already in the past. Every test fixes an input and asserts hand-computed instants
//  with an injected UTC calendar.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ExpiryPlanner")
struct ExpiryPlannerTests {

    /// The 09:00 instant on the day of `date`, in the injected calendar — the fixed hour
    /// expiry alerts fire at, computed the same way the planner does.
    private func alertInstant(onDayOf date: Date, calendar: Calendar) throws -> Date {
        let day = calendar.startOfDay(for: date)
        return try #require(calendar.date(bySettingHour: Medication.expiryAlertHour, minute: 0, second: 0, of: day))
    }

    @Test("A box expiring in the future warns 30 days before and again on the expiry day")
    func warnsThirtyDaysBeforeAndOnExpiry() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T08:00:00Z")
        let expiry = try isoDate("2026-08-31T00:00:00Z") // 83 days out, comfortably beyond 30
        let med = makeMedication(expiryDate: expiry)

        let alerts = med.expiryAlerts(from: reference, calendar: calendar)

        let warningDay = try #require(calendar.date(byAdding: .day, value: -Medication.expiryWarningLeadDays, to: expiry))
        let expectedUpcoming = try alertInstant(onDayOf: warningDay, calendar: calendar)
        let expectedOnExpiry = try alertInstant(onDayOf: expiry, calendar: calendar)
        #expect(alerts == [
            ExpiryAlert(kind: .upcoming, date: expectedUpcoming),
            ExpiryAlert(kind: .onExpiry, date: expectedOnExpiry)
        ])
    }

    @Test("A box already inside the 30-day window warns today and on the expiry day")
    func warnsTodayWhenInsideWindow() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T08:00:00Z")
        let expiry = try isoDate("2026-06-19T00:00:00Z") // 10 days out → the -30d warning is in the past
        let med = makeMedication(expiryDate: expiry)

        let alerts = med.expiryAlerts(from: reference, calendar: calendar)

        let expectedUpcoming = try alertInstant(onDayOf: reference, calendar: calendar) // clamped to today
        let expectedOnExpiry = try alertInstant(onDayOf: expiry, calendar: calendar)
        #expect(alerts == [
            ExpiryAlert(kind: .upcoming, date: expectedUpcoming),
            ExpiryAlert(kind: .onExpiry, date: expectedOnExpiry)
        ])
    }

    @Test("An already-expired box collapses to a single alert today")
    func alreadyExpiredAlertsTodayOnce() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T08:00:00Z")
        let expiry = try isoDate("2026-05-01T00:00:00Z") // in the past
        let med = makeMedication(expiryDate: expiry)

        let alerts = med.expiryAlerts(from: reference, calendar: calendar)

        let expectedToday = try alertInstant(onDayOf: reference, calendar: calendar)
        #expect(alerts == [ExpiryAlert(kind: .onExpiry, date: expectedToday)])
    }

    @Test("No stored expiry yields no alerts")
    func noExpiryNoAlerts() throws {
        let calendar = try utcCalendar()
        let reference = try isoDate("2026-06-09T08:00:00Z")
        let med = makeMedication(expiryDate: nil)
        #expect(med.expiryAlerts(from: reference, calendar: calendar).isEmpty)
    }
}
