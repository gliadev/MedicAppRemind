//
//  MedicationStoreActor+Shared.swift
//  MedicAppRemind
//
//  F5.S1 — App Intents run outside the app's view tree, so they can't reach the
//  `ModelContainer` that `RootView` builds and passes down. This process-wide
//  store is how the entity query and the intents reach the real data.
//
//  F5.S2 — It now builds over `PersistenceController.shared`, the *same* container
//  the app uses, so an intent's write propagates to the UI's `@Query` (one
//  container, no stale read) instead of landing in a second, isolated store.
//

import Foundation

extension MedicationStoreActor {
    /// The shared store over the app's single production container, built once on
    /// first use. `nil` when the store can't be opened — callers degrade gracefully
    /// (resolve nothing) rather than trapping, honouring the no-force-unwrap rule.
    static let shared: MedicationStoreActor? = {
        guard let container = PersistenceController.shared?.container else { return nil }
        return MedicationStoreActor(modelContainer: container)
    }()
}
