//
//  DraftParserSpikeDiagnostics.swift
//  MedicAppRemind
//
//  F10.S2 — TEMPORAL, parte del spike. Eliminar junto con Features/Spike.
//  Expone lo que el parser de producción oculta a propósito: el motivo exacto
//  de availability y el error crudo del framework, para anotarlos en el ADR.
//

import Foundation
import FoundationModels

struct DraftParserSpikeDiagnostics {

    /// The exact availability state, verbatim, for the spike report.
    var availabilityDescription: String {
        switch SystemLanguageModel.default.availability {
        case .available:
            return "available"
        case .unavailable(.deviceNotEligible):
            return "unavailable(deviceNotEligible)"
        case .unavailable(.appleIntelligenceNotEnabled):
            return "unavailable(appleIntelligenceNotEnabled)"
        case .unavailable(.modelNotReady):
            return "unavailable(modelNotReady)"
        case .unavailable(let other):
            return "unavailable(\(String(describing: other)))"
        }
    }

    /// Same call as the production parser but WITHOUT collapsing the error:
    /// returns a textual dump of the generated mirror or of the raw framework
    /// error. Never ships beyond the spike.
    func rawParse(_ text: String) async -> String {
        let session = LanguageModelSession(instructions: FoundationModelsDraftParser.instructions)
        do {
            let response = try await session.respond(
                to: text,
                generating: GeneratedMedicationDraft.self
            )
            return String(describing: response.content)
        } catch {
            return "RAW ERROR: \(String(describing: error))\n→ \(error.localizedDescription)"
        }
    }
}
