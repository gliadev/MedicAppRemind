//
//  CalendarSyncEnvironment.swift
//  MedicAppRemind
//
//  F4.S2 — Hands the calendar sync effect to the views that drive it. Provided once
//  by RootView over the shared store; `nil` until the app has wired its services, so
//  consumers degrade gracefully (a disabled toggle) instead of force-unwrapping.
//

import SwiftUI

extension EnvironmentValues {
    /// The app's calendar reconciliation service, or `nil` before it is wired.
    @Entry var calendarSync: CalendarSyncService? = nil
}
