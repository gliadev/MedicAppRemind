//
//  DoseRecurrence+EventKit.swift
//  MedicAppRemind
//
//  F4.S1 — The effect-side bridge: turns the pure DoseRecurrence into an EKRecurrenceRule.
//  The mapping that decides the recurrence (DoseFrequency.recurrence) is tested separately;
//  this thin, framework-bound conversion is exercised through CalendarService.
//

import Foundation
import EventKit

extension DoseRecurrence {
    /// Builds the EventKit rule for this recurrence, optionally bounded by an end date.
    ///
    /// - Parameter end: the last day the series should recur; open-ended when `nil`.
    func ekRecurrenceRule(until end: Date? = nil) -> EKRecurrenceRule {
        let recurrenceEnd = end.map(EKRecurrenceEnd.init(end:))
        switch cadence {
        case .daily:
            return EKRecurrenceRule(
                recurrenceWith: .daily,
                interval: max(1, interval),
                daysOfTheWeek: nil,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: recurrenceEnd
            )
        case .weekly:
            let days = weekdays
                .compactMap { EKWeekday(rawValue: $0.rawValue) }
                .map(EKRecurrenceDayOfWeek.init)
            return EKRecurrenceRule(
                recurrenceWith: .weekly,
                interval: max(1, interval),
                daysOfTheWeek: days.isEmpty ? nil : days,
                daysOfTheMonth: nil,
                monthsOfTheYear: nil,
                weeksOfTheYear: nil,
                daysOfTheYear: nil,
                setPositions: nil,
                end: recurrenceEnd
            )
        }
    }
}
