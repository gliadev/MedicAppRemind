//
//  LogDoseIntent.swift
//  MedicAppRemind
//
//  F5.S2 — "Registrar toma" for Siri and Shortcuts. A thin facade: it resolves the
//  shared store and delegates the clinical work to `logDose`, then formats the
//  spoken confirmation. The write lands in the shared container, so the app's
//  `@Query` reflects it immediately.
//

import AppIntents
import Foundation

struct LogDoseIntent: AppIntent {
    static let title: LocalizedStringResource = "Registrar toma"
    static let description = IntentDescription("Registra una toma y descuenta una pastilla del stock.")

    @Parameter(title: "Medicamento")
    var medication: MedicationEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Registrar toma de \(\.$medication)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let store = MedicationStoreActor.shared else {
            throw IntentError.medicationNotFound
        }
        let outcome = try await logDose(medicationID: medication.id, using: store, at: .now)
        let pills = outcome.remainingPills.formatted(.number)
        return .result(dialog: "Registrada la toma de \(outcome.medicationName). Te quedan \(pills) pastillas.")
    }
}
