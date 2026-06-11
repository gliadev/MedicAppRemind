//
//  DoseSchedule.swift
//  MedicAppRemind
//
//  F1.S1 — Domain entity. When a medication must be taken.
//

import Foundation

/// When a medication must be taken: the times of day plus the recurrence rule.
///
/// `times` holds the hour/minute of each daily dose as `DateComponents`; the
/// calendar day is supplied at scheduling time, never baked in here.
struct DoseSchedule: Codable, Equatable, Hashable {
    /// Times of day for each dose (hour/minute components).
    var times: [DateComponents]
    var frequency: DoseFrequency
    var startDate: Date
    /// Open-ended when `nil` (ongoing treatment).
    var endDate: Date?
}
