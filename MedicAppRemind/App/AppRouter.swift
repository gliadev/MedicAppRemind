//
//  AppRouter.swift
//  MedicAppRemind
//
//  F3.S3 — Owns the navigation path so a notification deep-link can drive it from
//  outside any view. The notification coordinator sets the destination; the root
//  navigation stack binds to `path`.
//

import Foundation
import Observation

/// App-wide navigation state, observed by the root `NavigationStack`.
///
/// `@MainActor` because it is UI state mutated from the main actor (a deep-link or
/// a user tap); `@Observable` so SwiftUI re-renders when `path` changes.
@MainActor
@Observable
final class AppRouter {
    /// The medication-detail stack. Empty shows the list; one id shows that
    /// medication's detail. Modeled as a `[UUID]` so it binds straight to
    /// `NavigationStack(path:)` with a `UUID` destination.
    var path: [UUID] = []

    /// Deep-links to a medication's detail, replacing whatever was on the stack.
    func openMedication(_ id: UUID) {
        path = [id]
    }
}
