//
//  StockStatus.swift
//  MedicAppRemind
//
//  F2.S3 — Pure presentation logic feeding the stock badge. No SwiftUI here, so
//  it stays unit-testable independent of the view.
//

import Foundation

/// How urgent a medication's remaining supply is, for the list badge.
/// Mirrors the `stockOk` / `stockLow` / `stockCritical` design tokens, plus
/// `unknown` for a medication that no schedule consumes.
enum StockLevel: Equatable {
    case ok
    case low
    case critical
    case unknown
}

/// What a stock badge shows: an urgency level and the whole number of days of
/// supply remaining (`nil` when no schedule consumes the medication).
struct StockStatus: Equatable {
    let level: StockLevel
    let remainingDays: Int?
}

extension Medication {
    /// Stock status for a list badge, given the medication's schedules.
    ///
    /// Uses the schedule that depletes soonest (the smallest `remainingDays`) —
    /// the safest figure to surface to a patient with several schedules.
    /// `.unknown` when no schedule consumes stock; `remainingDays` is floored to
    /// whole days (the last day a full dose is still available).
    func stockStatus(for schedules: [DoseSchedule]) -> StockStatus {
        let remainings = schedules.compactMap { remainingDays(for: $0) }
        guard let soonest = remainings.min() else {
            return StockStatus(level: .unknown, remainingDays: nil)
        }
        let wholeDays = Int(soonest.rounded(.down))
        let level: StockLevel =
            soonest <= 0 ? .critical
            : soonest <= Double(lowStockThresholdDays) ? .low
            : .ok
        return StockStatus(level: level, remainingDays: wholeDays)
    }
}
