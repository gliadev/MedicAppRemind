//
//  QueryRemainingIntent.swift
//  MedicAppRemind
//
//  F5.S2 — "Consultar restante" for Siri and Shortcuts. A thin facade: it resolves
//  the shared store, projects the plan to `RemainingSupply` (days via `DoseMath`),
//  and returns both a spoken dialog and an accessible snippet view. The dialog
//  omits the day count only when no schedule defines a consumption rate.
//

import AppIntents
import Foundation
import SwiftUI

struct QueryRemainingIntent: AppIntent {
    static let title: LocalizedStringResource = "Consultar restante"
    static let description = IntentDescription("Dice cuántas pastillas y días de tratamiento te quedan.")

    @Parameter(title: "Medicamento")
    var medication: MedicationEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Consultar lo que queda de \(\.$medication)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let store = MedicationStoreActor.shared,
              let plan = try await store.plan(id: medication.id) else {
            throw IntentError.medicationNotFound
        }
        let supply = remainingSupply(for: plan)
        let pills = supply.remainingPills.formatted(.number)

        let dialog: IntentDialog = if let days = supply.remainingDays {
            "Te quedan \(pills) pastillas de \(supply.medicationName), para unos \(days) días."
        } else {
            "Te quedan \(pills) pastillas de \(supply.medicationName)."
        }

        return .result(dialog: dialog, view: QueryRemainingSnippetView(supply: supply))
    }
}
