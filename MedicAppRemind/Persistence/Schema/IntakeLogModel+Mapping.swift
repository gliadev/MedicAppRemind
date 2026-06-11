//
//  IntakeLogModel+Mapping.swift
//  MedicAppRemind
//
//  F2.S1 — Mapping between the `IntakeLogModel` record and the `IntakeLog`
//  domain value type.
//

import Foundation

extension IntakeLogModel {
    /// Projects the record into its domain value.
    ///
    /// Throws `PersistenceError.orphanIntakeLog` when the record has no owning
    /// medication, since the domain `medicationID` cannot then be resolved.
    /// An unknown `statusRaw` falls back to `.pending`.
    func toDomain() throws -> IntakeLog {
        guard let medicationID = medication?.id else {
            throw PersistenceError.orphanIntakeLog
        }
        return IntakeLog(
            id: id,
            medicationID: medicationID,
            scheduledAt: scheduledAt,
            takenAt: takenAt,
            status: DoseStatus(rawValue: statusRaw) ?? .pending,
            pillsTaken: pillsTaken
        )
    }

    /// Copies the domain value's scalar fields onto the record. The owning
    /// `medication` relationship is wired by the actor, not here.
    func apply(_ log: IntakeLog) {
        id = log.id
        scheduledAt = log.scheduledAt
        takenAt = log.takenAt
        statusRaw = log.status.rawValue
        pillsTaken = log.pillsTaken
    }
}
