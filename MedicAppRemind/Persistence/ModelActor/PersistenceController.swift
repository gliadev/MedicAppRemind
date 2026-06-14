//
//  PersistenceController.swift
//  MedicAppRemind
//
//  F2.S2 — Owns the `ModelContainer`. Production stores to disk with CloudKit
//  off (flipped on in F7); tests pass `inMemory: true` for an ephemeral store.
//

import Foundation
import SwiftData

/// Builds and holds the app's `ModelContainer` for the V1 schema.
///
/// `Sendable` by construction — its only stored value is the `Sendable`
/// `ModelContainer` — so it can seed the `@MainActor` UI and the `@ModelActor`
/// store from one source.
struct PersistenceController {
    let container: ModelContainer

    /// - Parameter inMemory: `true` keeps the store off disk (tests). Production
    ///   uses `false`, which persists to the app's default store location.
    init(inMemory: Bool = false) throws {
        let schema = Schema(versionedSchema: MedicineSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            // F7.S1 — CloudKit sync over the user's private database. `.automatic`
            // resolves the container from the iCloud entitlement
            // (`iCloud.dev.gliadev.MedicAppRemind`) and uses the private database,
            // never the public one (health data — see F7.S3). The in-memory store
            // (tests, previews) stays on `.none`: tests never touch CloudKit.
            cloudKitDatabase: inMemory ? .none : .automatic
        )
        container = try ModelContainer(
            for: schema,
            migrationPlan: MedicineMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// The container's main-actor context, used by `@Query`-backed views (F2.S3).
    /// Writes never go through here — they go through `MedicationStoreActor`.
    @MainActor
    var mainContext: ModelContext { container.mainContext }
}
