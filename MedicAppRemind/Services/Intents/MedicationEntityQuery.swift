//
//  MedicationEntityQuery.swift
//  MedicAppRemind
//
//  F5.S1 — Resolves `MedicationEntity` values for the system. Both methods are
//  `async` and delegate to the `MedicationStoreActor`, so resolution always runs
//  off the main thread on the persistence actor — never touching `ModelContext`
//  here. The query maps the domain values the actor returns to entities, keeping
//  SwiftData out of the App Intents layer.
//

import AppIntents
import Foundation

/// Lets the system look up medications: by id when restoring a stored parameter,
/// and as suggestions when someone configures an intent in Shortcuts.
struct MedicationEntityQuery: EntityQuery {
    /// `nil` only when the on-disk store can't be opened, in which case the query
    /// resolves nothing rather than trapping. Tests inject an in-memory store.
    private let store: MedicationStoreActor?

    /// System-facing initializer required by `EntityQuery`. Resolves against the
    /// process-wide on-disk store so Siri and Shortcuts can reach the real data.
    init() {
        self.store = .shared
    }

    /// Test/wiring seam: resolves against a caller-supplied store, so the query
    /// logic is verifiable against an in-memory actor without the disk container.
    init(store: MedicationStoreActor) {
        self.store = store
    }

    /// The entities for these identifiers, skipping any id with no medication.
    func entities(for identifiers: [MedicationEntity.ID]) async throws -> [MedicationEntity] {
        guard let store else { return [] }
        var entities: [MedicationEntity] = []
        for id in identifiers {
            if let medication = try await store.medication(id: id) {
                entities.append(MedicationEntity(medication))
            }
        }
        return entities
    }

    /// Every stored medication, name-sorted by the store — the options the system
    /// suggests for a medication parameter.
    func suggestedEntities() async throws -> [MedicationEntity] {
        guard let store else { return [] }
        return try await store.fetchAll().map(MedicationEntity.init)
    }
}
