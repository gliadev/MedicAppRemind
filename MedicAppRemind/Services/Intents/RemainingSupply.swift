//
//  RemainingSupply.swift
//  MedicAppRemind
//
//  F5.S2 — The testable core of `QueryRemainingIntent`. The day count comes from
//  `DoseMath` (`Medication.remainingDays(for:)`); this reducer only selects the
//  most conservative schedule and floors to whole days for presentation. No
//  clinical math is recomputed here.
//

import Foundation

/// What a "how much do I have left" query reports, before any dialog formatting.
struct RemainingSupply: Equatable, Sendable {
    var medicationName: String
    var remainingPills: Double
    /// Whole days of supply at the soonest-depleting schedule, or `nil` when no
    /// schedule defines a consumption rate (nothing to deplete).
    var remainingDays: Int?
}

/// Projects a medication plan to its remaining supply.
///
/// With several schedules drawing on the same stock, the soonest depletion (the
/// smallest `remainingDays`) is reported — the safest answer for the patient,
/// never the rosiest. Days are floored: the last day a full dose is still available.
func remainingSupply(for plan: MedicationPlan) -> RemainingSupply {
    let medication = plan.medication
    let soonestDays = plan.schedules
        .compactMap { medication.remainingDays(for: $0) }
        .min()
    return RemainingSupply(
        medicationName: medication.name,
        remainingPills: medication.currentStock,
        remainingDays: soonestDays.map { Int($0.rounded(.down)) }
    )
}
