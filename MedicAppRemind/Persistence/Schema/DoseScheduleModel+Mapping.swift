//
//  DoseScheduleModel+Mapping.swift
//  MedicAppRemind
//
//  F2.S1 — Mapping between the `DoseScheduleModel` record and the `DoseSchedule`
//  domain value type. Frequency and times are stored as encoded `Data`.
//

import Foundation

extension DoseScheduleModel {
    /// Reconstructs the domain schedule by decoding the stored payloads.
    ///
    /// Throws `PersistenceError.corruptedScheduleData` when either payload is
    /// absent or fails to decode — clinical data is never silently defaulted.
    /// A local coder avoids a non-`Sendable` global under strict concurrency.
    func toDomain() throws -> DoseSchedule {
        guard let frequencyData, let timesData else {
            throw PersistenceError.corruptedScheduleData
        }
        let decoder = JSONDecoder()
        do {
            let frequency = try decoder.decode(DoseFrequency.self, from: frequencyData)
            let times = try decoder.decode([DateComponents].self, from: timesData)
            return DoseSchedule(
                times: times,
                frequency: frequency,
                startDate: startDate,
                endDate: endDate
            )
        } catch {
            throw PersistenceError.corruptedScheduleData
        }
    }

    /// Encodes the domain schedule onto the record. The owning `medication`
    /// relationship is wired by the actor, not here.
    func apply(_ schedule: DoseSchedule) throws {
        let encoder = JSONEncoder()
        frequencyData = try encoder.encode(schedule.frequency)
        timesData = try encoder.encode(schedule.times)
        startDate = schedule.startDate
        endDate = schedule.endDate
    }
}
