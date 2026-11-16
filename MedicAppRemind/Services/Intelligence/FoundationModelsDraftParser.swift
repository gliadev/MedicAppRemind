//
//  FoundationModelsDraftParser.swift
//  MedicAppRemind
//
//  F10.S2 — The real parser: one-shot guided generation against the on-device
//  system model (iOS 26 APIs only). Every framework failure collapses into
//  DraftParserError.couldNotParse — the UI has exactly one failure path and
//  the person's text is never lost (it travels back in the draft's notes).
//

import Foundation
import FoundationModels

struct FoundationModelsDraftParser: MedicationDraftParsing {

    /// Static role prompt. English on purpose (it is code, not UI); the
    /// person's text is passed verbatim as the prompt, in Spanish or English.
    private static let instructions = """
        You extract structured data about ONE medication from a short free-text \
        description a person writes or dictates, in Spanish or English.
        Rules:
        - Only extract values the text explicitly states. Never invent, infer, \
        or default a value that is not stated.
        - Omit every field the text does not mention.
        - "name" is the medication name alone, without the strength.
        - If the text does not describe a medication regimen, omit all fields.
        - Never produce medical advice, warnings, or commentary.
        """

    var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    func parseDraft(from text: String) async throws -> MedicationDraft {
        guard isAvailable else { throw DraftParserError.couldNotParse }
        let session = LanguageModelSession(instructions: Self.instructions)
        do {
            let response = try await session.respond(
                to: text,
                generating: GeneratedMedicationDraft.self
            )
            return response.content.toDomainDraft(sourceText: text)
        } catch {
            throw DraftParserError.couldNotParse
        }
    }
}
