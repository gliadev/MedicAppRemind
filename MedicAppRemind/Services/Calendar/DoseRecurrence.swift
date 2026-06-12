//
//  DoseRecurrence.swift
//  MedicAppRemind
//
//  F4.S1 — The recurrence parameters an EKRecurrenceRule needs, distilled from a
//  dose frequency as a plain value so the mapping stays pure and testable without
//  EventKit. The EventKit bridge lives in DoseRecurrence+EventKit (the effect side).
//

import Foundation

/// A calendar recurrence reduced to the parameters `EKRecurrenceRule` requires.
///
/// `Sendable` by construction (every stored property is `Sendable`), so the conformance
/// is inferred and must not be restated.
struct DoseRecurrence: Equatable {
    /// How often the event repeats. Only the cadences this app produces.
    enum Cadence: Equatable {
        case daily
        case weekly
    }

    var cadence: Cadence
    /// Repeat interval; `1` means every day/week. Always `> 0` for a real recurrence.
    var interval: Int
    /// Weekdays the event repeats on. Empty for `.daily`.
    var weekdays: [Weekday]
}
