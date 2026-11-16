//
//  FoundationModelsDraftParser.swift
//  MedicAppRemind
//
//  F10.S2 — The real parser: one-shot plain-text response decoded as JSON.
//  Guided generation is deliberately NOT used: the 2026-11-16 spike proved it
//  always triggers default guardrails on medication text, while String
//  responses honor Guardrails.permissiveContentTransformations (ADR05).
//  Every failure collapses into DraftParserError.couldNotParse — the UI has
//  exactly one failure path and the person's text is never lost (it travels
//  back in the draft's notes).
//

import Foundation
import FoundationModels

struct FoundationModelsDraftParser: MedicationDraftParsing {

    /// Static role prompt. English on purpose (it is code, not UI); the
    /// person's text is passed verbatim as the prompt, in Spanish or English.
    /// Internal (not private) only while the F10.S2 spike reuses it.
    static let instructions = """
        You extract structured data about ONE medication from a short free-text \
        description a person writes or dictates, in Spanish or English.
        Respond ONLY with a single compact JSON object, no prose, no code fences.
        Use exactly these keys, each one only when the text explicitly states \
        its value:
        "name" (string: the medication name alone, without the strength), \
        "doseLabel" (string: the strength exactly as written, e.g. "600 mg"), \
        "pillsPerDose" (number: units taken per single dose; half of one is 0.5), \
        "form" ("pill" | "capsule" | "tablet" | "liquid" | "injection" | "other"), \
        "currentStock" (number: units the person says they currently have), \
        "frequencyKind" ("daily" | "everyNHours" | "weekdays" — exactly one), \
        "everyNHours" (integer, only when frequencyKind is "everyNHours"), \
        "weekdays" (array of English lowercase day names "monday".."sunday", \
        only when frequencyKind is "weekdays"), \
        "timesOfDay" (array of {"hour": int, "minute": int}, 24-hour clock, \
        only times the text explicitly states).
        Never invent, infer, or default a value the text does not state. \
        Omit every key the text does not cover. When the text only names a \
        medication and nothing else, the JSON contains only "name" — never a \
        typical strength or a typical schedule for that medication.
        If the text does not describe a medication regimen, respond with {}.
        Never produce medical advice, warnings, or commentary.
        """

    /// Spike F10.S2 (2026-11-16): `Guardrails.default` refuses every medication
    /// sentence ("May contain sensitive content"), so this feature is only
    /// viable with `.permissiveContentTransformations` — the sanctioned mode
    /// for transforming user-provided text. See ADR05.
    /// Internal (not private) only while the spike reuses it.
    static func makeModel() -> SystemLanguageModel {
        SystemLanguageModel(useCase: .general, guardrails: .permissiveContentTransformations)
    }

    var isAvailable: Bool {
        if case .available = Self.makeModel().availability { return true }
        return false
    }

    func parseDraft(from text: String) async throws -> MedicationDraft {
        let model = Self.makeModel()
        guard case .available = model.availability else { throw DraftParserError.couldNotParse }
        let session = LanguageModelSession(model: model, instructions: Self.instructions)
        do {
            let response = try await session.respond(to: text)
            let generated = try GeneratedMedicationDraft.decode(fromModelOutput: response.content)
            guard !generated.isEmpty else { throw DraftParserError.couldNotParse }
            return generated.toDomainDraft(sourceText: text)
        } catch {
            throw DraftParserError.couldNotParse
        }
    }
}
