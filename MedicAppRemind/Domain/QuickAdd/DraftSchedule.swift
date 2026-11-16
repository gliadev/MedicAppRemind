//
//  DraftSchedule.swift
//  MedicAppRemind
//
//  F10.S1 — Quick-add draft schedule. A deliberately flat mirror of
//  DoseSchedule that an on-device model can generate (plain hour/minute pairs,
//  no DateComponents). Converting back to Domain types is Domain code
//  (MedicationDraft+Editor.swift), never the LLM's job.
//

import Foundation

/// A time of day in a drafted schedule, on the 24-hour clock.
struct DraftTime: Equatable {
    var hour: Int
    var minute: Int
}

/// Recurrence of a drafted schedule — a minimal mirror of `DoseFrequency`.
enum DraftFrequencyKind: Equatable {
    case daily
    case everyNHours(Int)
    case weekdays([Weekday])
}

/// A dose schedule as drafted from free text, before Domain conversion.
///
/// `timesOfDay` is optional because the text may not mention times at all;
/// for `.everyNHours` a single entry acts as the interval anchor ("primera toma").
struct DraftSchedule: Equatable {
    var timesOfDay: [DraftTime]?
    var kind: DraftFrequencyKind
}
