//
//  ScheduleReminderIntent.swift
//  MedicAppRemind
//
//  F5.S2 — "Programar recordatorio" for Siri and Shortcuts. Adds a time of day to
//  the medication's schedule through the shared store, then reprograms every
//  reminder the same way the rest of the app does after a mutation
//  (`refreshAllReminders`), so it never clobbers other medications' reminders.
//

import AppIntents
import Foundation

struct ScheduleReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Programar recordatorio"
    static let description = IntentDescription("Añade una hora de toma y programa el recordatorio.")
    // Mutating the dose schedule requires an unlocked device.
    static var authenticationPolicy: IntentAuthenticationPolicy { .requiresLocalDeviceAuthentication }

    @Parameter(title: "Medicamento")
    var medication: MedicationEntity

    @Parameter(title: "Hora")
    var time: Date

    static var parameterSummary: some ParameterSummary {
        Summary("Recordar \(\.$medication) a las \(\.$time)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let store = MedicationStoreActor.shared else {
            throw IntentError.medicationNotFound
        }
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        guard let plan = try await store.addDoseTime(components, toMedication: medication.id) else {
            throw IntentError.medicationNotFound
        }

        // Reprogram from the full set of plans, like the notification path does, so
        // adding one time never cancels another medication's pending reminders.
        let plans = try await store.fetchPlans()
        await NotificationService().refreshAllReminders(for: plans)

        let when = time.formatted(date: .omitted, time: .shortened)
        return .result(dialog: "Te recordaré tomar \(plan.medication.name) a las \(when).")
    }
}
