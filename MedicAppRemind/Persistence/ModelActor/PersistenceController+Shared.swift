//
//  PersistenceController+Shared.swift
//  MedicAppRemind
//
//  F5.S2 — A single production controller shared by the SwiftUI app and the App
//  Intents runtime. One `ModelContainer` backs both, so a write an intent makes
//  through the `MedicationStoreActor` propagates to the `mainContext` the UI's
//  `@Query` observes — there is no second container and no stale read. The app
//  (`MedicAppRemindApp`) and `MedicationStoreActor.shared` both resolve through here.
//

import Foundation
import SwiftData

extension PersistenceController {
    /// The process-wide production controller, built once on first use. `nil` when
    /// the on-disk store can't be opened — callers degrade gracefully (the app
    /// shows a recovery screen; intents resolve nothing) rather than trapping.
    static let shared: PersistenceController? = try? PersistenceController()
}
