//
//  ServicesTestSupport.swift
//  MedicAppRemindTests
//
//  F3 — Deterministic fixtures and helpers for the services test suite.
//  Dates are fixed; nothing here reads the wall clock.
//

import Foundation
import Testing
@testable import MedicAppRemind

/// Gregorian calendar pinned to UTC so date math is independent of the test
/// machine's time zone.
func utcCalendar() throws -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
    return calendar
}

/// Parses an ISO-8601 instant for fixtures. Never the wall clock.
func isoDate(_ iso: String) throws -> Date {
    try Date(iso, strategy: .iso8601)
}

/// Pairs a medication with its schedules — the reminder planner's input unit.
func makePlan(_ medication: Medication, _ schedules: [DoseSchedule]) -> MedicationPlan {
    MedicationPlan(medication: medication, schedules: schedules)
}
