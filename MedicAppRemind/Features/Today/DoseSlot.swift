//
//  DoseSlot.swift
//  MedicAppRemind
//
//  F6.S1 — Value type for a single scheduled dose occurrence on a given day.
//  `DayPeriod` groups slots into morning / afternoon / evening sections.
//  The static `slots(from:logs:on:calendar:)` factory maps SwiftData query
//  results to domain value types; it is `@MainActor` because it reads from
//  main-actor–bound SwiftData model objects delivered by `@Query`.
//

import Foundation
import SwiftData

/// Broad time window a dose falls in — drives TodayView's section headers.
enum DayPeriod: String, CaseIterable, Equatable, Hashable, Identifiable {
    case morning = "Mañana"
    case afternoon = "Mediodía"
    case evening = "Noche"

    var id: String { rawValue }

    /// Maps an hour of the day (0–23) to the matching period.
    static func forHour(_ hour: Int) -> DayPeriod {
        switch hour {
        case 0..<12: .morning
        case 12..<17: .afternoon
        default: .evening
        }
    }
}

/// One scheduled dose occurrence on a given calendar day.
///
/// `id` is the deterministic `doseOccurrenceID(medicationID:scheduledAt:)` so
/// a log recorded via `MedicationStoreActor.recordIntake` maps directly to
/// this slot's `id` and `isTaken` resolves without extra fetches.
struct DoseSlot: Identifiable, Equatable {
    var id: UUID
    var medicationID: UUID
    var medicationName: String
    var doseLabel: String
    var pillsPerDose: Double
    var scheduledAt: Date
    var period: DayPeriod
    var isTaken: Bool
}

extension Collection where Element == DoseSlot {
    /// The day is complete when there is at least one scheduled dose and every
    /// one has been taken. An empty day is never "complete" — there is nothing
    /// to celebrate when no doses are due.
    var isDayComplete: Bool {
        !isEmpty && allSatisfy(\.isTaken)
    }
}

extension DoseSlot {
    /// All dose slots for `date`, derived from active medication schedules and
    /// matched against the supplied `IntakeLogModel` records for that day.
    ///
    /// `@MainActor` because it reads directly from SwiftData model objects
    /// owned by the main actor's `ModelContext` (delivered by `@Query`).
    @MainActor
    static func slots(
        from medications: [MedicationModel],
        logs: [IntakeLogModel],
        on date: Date,
        calendar: Calendar
    ) -> [DoseSlot] {
        let takenIDs = Set(
            logs.filter { $0.statusRaw == DoseStatus.taken.rawValue }.map(\.id)
        )
        return medications.flatMap { model -> [DoseSlot] in
            let medication = model.toDomain()
            let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
            return schedules.flatMap { schedule -> [DoseSlot] in
                schedule.fireTimes(on: date, calendar: calendar).map { fireDate in
                    let occID = doseOccurrenceID(medicationID: medication.id, scheduledAt: fireDate)
                    let hour = calendar.component(.hour, from: fireDate)
                    return DoseSlot(
                        id: occID,
                        medicationID: medication.id,
                        medicationName: medication.name,
                        doseLabel: medication.doseLabel,
                        pillsPerDose: medication.pillsPerDose,
                        scheduledAt: fireDate,
                        period: .forHour(hour),
                        isTaken: takenIDs.contains(occID)
                    )
                }
            }
        }
        .sorted { $0.scheduledAt < $1.scheduledAt }
    }
}
