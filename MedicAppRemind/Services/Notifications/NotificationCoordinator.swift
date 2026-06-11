//
//  NotificationCoordinator.swift
//  MedicAppRemind
//
//  F3.S3 — The effect side of notification responses: the delegate that turns a
//  user's interaction into persistence writes and navigation. It owns no clinical
//  logic — it parses the response, asks the pure `doseResponse`/`recordedDose`
//  reducers what to do, and dispatches that to the store actor, the notification
//  service, and the router.
//

import Foundation
import UserNotifications

/// Receives notification responses and foreground presentations, dispatching the
/// pure decision to the store, the notification service and the router.
///
/// `@MainActor` because it touches the router (UI state); data work hops to the
/// `MedicationStoreActor`. The delegate callbacks are `nonisolated` so they can
/// extract the `Sendable` essentials off the non-`Sendable` notification objects
/// before crossing onto the main actor.
@MainActor
final class NotificationCoordinator: NSObject {
    private let store: MedicationStoreActor
    private let notificationService: NotificationService
    private let router: AppRouter

    init(store: MedicationStoreActor, notificationService: NotificationService, router: AppRouter) {
        self.store = store
        self.notificationService = notificationService
        self.router = router
    }

    /// Dispatches a decided outcome. The `scheduledAt` instant identifies the dose
    /// occurrence, so "Tomada" stays idempotent across a double tap.
    private func handle(_ outcome: DoseResponse, scheduledAt: Date) async {
        switch outcome {
        case .recordTaken(let medicationID):
            await recordTaken(medicationID: medicationID, scheduledAt: scheduledAt)
        case .snooze(let medicationID):
            await snooze(medicationID: medicationID)
        case .openDetail(let medicationID):
            router.openMedication(medicationID)
        case .ignore:
            break
        }
    }

    /// Logs the taken dose and decrements stock through the actor, then reprograms
    /// reminders (stock moved, so the refill date moved). Idempotent: the actor
    /// no-ops a repeat of the same occurrence, and we only refresh when it wrote.
    private func recordTaken(medicationID: UUID, scheduledAt: Date) async {
        guard let medication = try? await store.medication(id: medicationID) else { return }
        let recorded = recordedDose(
            for: medication,
            scheduledAt: scheduledAt,
            takenAt: .now,
            logID: doseOccurrenceID(medicationID: medicationID, scheduledAt: scheduledAt)
        )
        let didRecord = (try? await store.recordIntake(recorded.log, decrementingStockBy: recorded.stockDecrement)) ?? false
        guard didRecord else { return }
        let plans = (try? await store.fetchPlans()) ?? []
        await notificationService.refreshAllReminders(for: plans)
    }

    /// Reschedules the reminder a few minutes out for the "Posponer" action.
    private func snooze(medicationID: UUID) async {
        guard let medication = try? await store.medication(id: medicationID) else { return }
        await notificationService.scheduleSnooze(for: medication)
    }
}

extension NotificationCoordinator: UNUserNotificationCenterDelegate {
    /// Shows dose reminders while the app is in the foreground (banner + sound),
    /// so an open app never silently swallows a dose.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    /// Extracts the `Sendable` essentials from the response, then dispatches the
    /// decided outcome on the main actor.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let payload = DosePayload(userInfo: response.notification.request.content.userInfo)
        let outcome = doseResponse(actionIdentifier: response.actionIdentifier, medicationID: payload?.medicationID)
        let scheduledAt = response.notification.date
        await handle(outcome, scheduledAt: scheduledAt)
    }
}
