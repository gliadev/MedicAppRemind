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
    /// Same model instance as production (permissive guardrails).
    var availabilityDescription: String {
        switch FoundationModelsDraftParser.makeModel().availability {
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

    /// v4 — runs the REAL production parser end to end (String + JSON decode)
    /// and shows the raw model text next to the decoded Domain draft, so the
    /// device matrix for the ADR captures both.
    func rawParse(_ text: String) async -> String {
        let raw = await rawStringDump(text)
        let parsed: String
        do {
            let draft = try await FoundationModelsDraftParser().parseDraft(from: text)
            parsed = String(describing: draft)
        } catch {
            parsed = "ERROR: \(String(describing: error))"
        }
        return "RAW → \(raw)\n\nPARSED → \(parsed)"
    }

    /// The same call the production parser makes, without decoding.
    private func rawStringDump(_ text: String) async -> String {
        let session = LanguageModelSession(
            model: FoundationModelsDraftParser.makeModel(),
            instructions: FoundationModelsDraftParser.instructions
        )
        do {
            let response = try await session.respond(to: text)
            return response.content
        } catch {
            return "RAW ERROR: \(String(describing: error))\n→ \(error.localizedDescription)"
        }
    }
}
