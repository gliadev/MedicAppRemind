//
//  Weekday.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. Day of the week for weekly dose schedules.
//

import Foundation

/// A day of the week.
///
/// Raw values align with `Calendar`'s Gregorian weekday component
/// (Sunday = 1 ... Saturday = 7) so `DoseMath` (F1.S2) can match schedule
/// days against `Calendar` queries without a translation table.
enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}
