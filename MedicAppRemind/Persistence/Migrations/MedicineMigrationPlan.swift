//
//  MedicineMigrationPlan.swift
//  MedicAppRemind
//
//  F2.S1 — Migration plan. Only V1 today; the structure is in place so adding
//  a version later is a new schema entry plus a stage, not a redesign.
//

import Foundation
import SwiftData

/// Migration plan for the persistence schema. Holds the ordered list of schema
/// versions and the stages that move data between them — empty while V1 is the
/// only version.
enum MedicineMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [MedicineSchemaV1.self] }

    static var stages: [MigrationStage] { [] }
}
