//
//  DoseFrequencyTests.swift
//  MedicAppRemindTests
//
//  F1.S1 — Codable round-trip for the associated-value cases of `DoseFrequency`.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("DoseFrequency")
struct DoseFrequencyTests {

    @Test("The .daily case round-trips")
    func dailyRoundTrips() throws {
        let decoded = try roundTripJSON(DoseFrequency.daily)
        #expect(decoded == .daily)
    }

    @Test("The .weekdays case preserves its associated days")
    func weekdaysRoundTripsWithAssociatedValues() throws {
        let original = DoseFrequency.weekdays([.monday, .wednesday, .friday])
        let decoded = try roundTripJSON(original)
        #expect(decoded == .weekdays([.monday, .wednesday, .friday]))
    }

    @Test("The .everyNHours case preserves its interval")
    func everyNHoursRoundTripsWithInterval() throws {
        let decoded = try roundTripJSON(DoseFrequency.everyNHours(8))
        #expect(decoded == .everyNHours(8))
    }

    @Test("Different associated values are not equal")
    func differingIntervalsAreNotEqual() {
        #expect(DoseFrequency.everyNHours(8) != .everyNHours(12))
    }
}
