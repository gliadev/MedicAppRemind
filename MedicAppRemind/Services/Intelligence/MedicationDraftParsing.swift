//
//  MedicationDraftParsing.swift
//  MedicAppRemind
//
//  F10.S2 — Contract for turning a free-text medication description into a
//  Domain draft. Features depend on this protocol, never on FoundationModels:
//  `isAvailable` lets the UI decide visibility without importing the framework,
//  and tests/previews inject a fake.
//

import Foundation

/// Parses a person's free-text description of a medication into a draft.
protocol MedicationDraftParsing: Sendable {
    /// Whether the underlying model can take requests right now. The UI hides
    /// (never disables) the quick-add entry point when this is `false`.
    var isAvailable: Bool { get }

    /// Returns a structured draft for `text`, or throws `DraftParserError`.
    func parseDraft(from text: String) async throws -> MedicationDraft
}

/// The single public parser failure. Every underlying cause — guardrails,
/// unsupported language, context size, availability lost mid-flight — collapses
/// here: the UI shows one kind message and preserves the dictated text (F10
/// decision 6), so a finer-grained error would never change behaviour.
enum DraftParserError: LocalizedError, Equatable {
    case couldNotParse

    var errorDescription: String? {
        String(localized: "No se ha podido interpretar la descripción. Puedes rellenar los datos a mano; tu texto queda guardado en las notas.")
    }
}
