//
//  RootView.swift
//  MedicAppRemind
//
//  F3.S3 — Wires the notification stack to the running app: it builds the store
//  actor, notification service and coordinator over the shared container, makes
//  the coordinator the notification-center delegate, registers the actionable
//  dose category, requests authorization, and reprograms reminders at launch.
//  The router is shared into the environment so deep-links drive navigation.
//

import SwiftUI
import SwiftData
import UserNotifications

/// The app's root once the store is available. Owns the navigation router and the
/// notification coordinator (retained here because the center holds its delegate
/// weakly), and bootstraps notifications on first appearance.
@MainActor
struct RootView: View {
    let container: ModelContainer

    @State private var router = AppRouter()
    @State private var coordinator: NotificationCoordinator?

    var body: some View {
        MedicationListView()
            .modelContainer(container)
            .environment(router)
            .task { await bootstrapNotifications() }
    }

    /// Builds the notification stack once and primes it: delegate, category,
    /// authorization, and an initial reminder refresh. Idempotent — re-running
    /// when the coordinator already exists is a no-op.
    private func bootstrapNotifications() async {
        guard coordinator == nil else { return }
        let store = MedicationStoreActor(modelContainer: container)
        let service = NotificationService()
        let coordinator = NotificationCoordinator(store: store, notificationService: service, router: router)
        self.coordinator = coordinator

        UNUserNotificationCenter.current().delegate = coordinator
        await service.registerDoseCategory()
        _ = await service.requestAuthorization()
        let plans = (try? await store.fetchPlans()) ?? []
        await service.refreshAllReminders(for: plans)
    }
}
