//
//  ScheduleKind.swift
//  MedicAppRemind
//
//  AX-04 — Editing mode for the schedule editor. Bridges the editor's form state
//  (a discrete mode + a weekday set + an interval) to the Domain's `DoseFrequency`
//  and back, as pure value logic so it can be tested without SwiftUI.
//

import Foundation

/// The discrete pauta mode the editor presents, independent of the associated
/// values a `DoseFrequency` carries. Drives the segmented picker.
enum ScheduleKind: CaseIterable, Hashable {
    /// Every day at the listed times.
    case daily
    /// Only on selected weekdays, at the listed times.
    case weekdays
    /// Every N hours, anchored on a start time.
    case everyNHours

    /// The editing mode that matches an existing frequency.
    init(_ frequency: DoseFrequency) {
        switch frequency {
        case .daily:       self = .daily
        case .weekdays:    self = .weekdays
        case .everyNHours: self = .everyNHours
        }
    }
}

extension DoseFrequency {
    /// Clinically common dosing intervals offered in the editor, in hours.
    static let intervalPresets = [4, 6, 8, 12]

    /// The default interval (hours) for a fresh "cada N horas" pauta.
    static let defaultIntervalHours = 8

    /// Builds a frequency from the editor's form state.
    ///
    /// - `weekdays` is sorted by `Calendar` weekday raw value so the stored value is
    ///   deterministic regardless of the order the user tapped the day chips.
    /// - `weekdays`/`intervalHours` are read only for the case `kind` selects, so the
    ///   editor can keep both around while the user switches modes.
    init(kind: ScheduleKind, weekdays: Set<Weekday>, intervalHours: Int) {
        switch kind {
        case .daily:
            self = .daily
        case .weekdays:
            self = .weekdays(weekdays.sorted { $0.rawValue < $1.rawValue })
        case .everyNHours:
            self = .everyNHours(intervalHours)
        }
    }

    /// The selected weekdays, empty for non-weekly frequencies. Lets the editor seed
    /// its day chips from an existing schedule.
    var selectedWeekdays: Set<Weekday> {
        if case .weekdays(let days) = self { return Set(days) }
        return []
    }

    /// The interval in hours, `nil` for non-interval frequencies. Lets the editor seed
    /// its interval picker from an existing schedule.
    var intervalHours: Int? {
        if case .everyNHours(let hours) = self { return hours }
        return nil
    }
}
