//
//  StoreActorEnvironment.swift
//  MedicAppRemind
//
//  F6.S1 — Environment key that hands the shared `MedicationStoreActor` to
//  views that need to write (e.g. TodayView registering a dose). Provided once
//  by RootView over the shared container; `nil` until the app has wired its
//  services, so consumers degrade gracefully instead of force-unwrapping.
//

import SwiftUI

extension EnvironmentValues {
    /// The app's medication store, or `nil` before it is wired by `RootView`.
    @Entry var medicationStore: MedicationStoreActor? = nil
}
