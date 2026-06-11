//
//  DoseFrequency.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Recurrence rule of a dose schedule.
//

import Foundation

/// How often a medication is scheduled.
///
/// Codable conformance is compiler-synthesized for the associated values, so
/// `.weekdays` and `.everyNHours` round-trip without a manual coder.
enum DoseFrequency: Codable, Equatable, Hashable {
    /// Every day.
    case daily
    /// Only on the listed weekdays.
    case weekdays([Weekday])
    /// Every `n` hours across the day (e.g. `8` → three doses/day).
    case everyNHours(Int)
}
