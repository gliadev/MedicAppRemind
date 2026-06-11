//
//  MedicineSchemaV1.swift
//  MedicAppRemind
//
//  F2.S1 — Versioned schema, V1. Established from the first release so future
//  migrations are additive (a new `MedicineSchemaVn` + a stage), never a rewrite.
//

import Foundation
import SwiftData

/// Version 1 of the persistence schema. `VersionedSchema` is an enum by Apple's
/// own convention — it is a namespace for a version, not a static-only utility.
enum MedicineSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [MedicationModel.self, DoseScheduleModel.self, IntakeLogModel.self]
    }
}
