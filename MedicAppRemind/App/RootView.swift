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

    /// The single store actor over the shared container, reused by the notification
    /// bootstrap and by calendar sync so both write through the same off-main path.
    private let store: MedicationStoreActor
    private let calendarSync: CalendarSyncService

    @State private var router = AppRouter()
    @State private var coordinator: NotificationCoordinator?
    @State private var syncMonitor = CloudSyncMonitor()
    @State private var lockMonitor = AppLockMonitor()
    @Environment(\.scenePhase) private var scenePhase

    init(container: ModelContainer) {
        self.container = container
        let store = MedicationStoreActor(modelContainer: container)
        self.store = store
        self.calendarSync = CalendarSyncService(calendarService: CalendarService(), store: store)
    }

    var body: some View {
        TabView {
            Tab("Hoy", systemImage: "calendar") {
                TodayView()
            }
            Tab("Medicamentos", systemImage: "pills") {
                MedicationListView()
            }
        }
        .modelContainer(container)
        .environment(router)
        .environment(\.calendarSync, calendarSync)
        .environment(\.medicationStore, store)
        .environment(\.cloudSyncMonitor, syncMonitor)
        .environment(lockMonitor)
        .task { await bootstrapNotifications() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { lockMonitor.lock() }
        }
        .overlay {
            if lockMonitor.isLocked {
                LockScreenView { await lockMonitor.unlock() }
            }
        }
    }

    /// Builds the notification stack once and primes it: delegate, category,
    /// authorization, and an initial reminder refresh. Idempotent — re-running
    /// when the coordinator already exists is a no-op.
    private func bootstrapNotifications() async {
        syncMonitor.start()
        guard coordinator == nil else { return }
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
