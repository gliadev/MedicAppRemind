//
//  DescribeSheetState.swift
//  MedicAppRemind
//
//  F10.S3 — Pure state machine of the "Describir" sheet plus the flow that
//  turns the person's text into an editor outcome. Mirrors the
//  ScanViewfinderState discipline: no dead ends, always cancelable, and a
//  result that arrives after cancellation can never resurrect the sheet.
//

import Foundation

/// What the describe sheet is currently showing.
enum DescribeSheetState: Equatable {
    /// Waiting for the person to write or dictate (the resting state).
    case idle
    /// A parse request is in flight; the UI shows an accessible spinner.
    case loading
    /// The parse failed; the single kind message is shown and retry is offered.
    case failed
}

/// Inputs that move the describe sheet between states.
enum DescribeEvent: Equatable {
    /// The person tapped the primary button with the current text.
    case interpretTapped(text: String)
    case parseSucceeded
    case parseFailed
    /// The person dismissed or cancelled, from any state.
    case cancelled
}

extension DescribeSheetState {
    /// Advances the sheet given an event, returning the next state.
    ///
    /// Results only apply from `.loading`, so a response that lands after the
    /// person cancelled is ignored; blank text never starts a request.
    func reduced(on event: DescribeEvent) -> DescribeSheetState {
        switch event {
        case .interpretTapped(let text):
            guard self != .loading else { return self }
            let hasContent = text.contains { !$0.isWhitespace }
            return hasContent ? .loading : self
        case .parseSucceeded:
            return self == .loading ? .idle : self
        case .parseFailed:
            return self == .loading ? .failed : self
        case .cancelled:
            return .idle
        }
    }
}

/// What the describe sheet hands back to the editor.
enum DescribeFlowResult: Equatable {
    /// The parse succeeded: apply these values onto the open editor.
    case prefill(MedicationEditorPrefill)
    /// The parse failed and the person fell back to manual entry: their text
    /// goes to the medication's notes so nothing said (or dictated) is lost.
    case failed(notesText: String)
}

/// Runs one parse attempt against the parsing contract. Pure with respect to
/// the parser: success converts through the S1 prefill (with all its clamps),
/// any failure preserves the person's text verbatim.
func describeFlowResult(text: String, parser: any MedicationDraftParsing) async -> DescribeFlowResult {
    do {
        let draft = try await parser.parseDraft(from: text)
        return .prefill(draft.editorPrefill())
    } catch {
        return .failed(notesText: text)
    }
}

/// Whether the "Describir" entry point exists at all: only with a parser
/// present AND available (F10 decision 3 — hidden, never disabled).
func showsDescribeEntry(_ parser: (any MedicationDraftParsing)?) -> Bool {
    parser?.isAvailable == true
}
