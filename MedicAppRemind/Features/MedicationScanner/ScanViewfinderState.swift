//
//  ScanViewfinderState.swift
//  MedicAppRemind
//
//  FX.S3 — The mutually-exclusive states of the box-scanner viewfinder and the
//  pure reducer that advances between them. Extracted from the view so the state
//  machine is unit-tested; the live camera itself isn't. Every failure degrades
//  to a recoverable state — manual entry or retry — never a dead end.
//

import Foundation

/// What the scanner screen is currently showing.
enum ScanViewfinderState: Equatable {
    /// Looking for a code (the resting state).
    case scanning
    /// A code routed to an identifier; CIMA is being queried.
    case looking(MedicineIdentifier)
    /// Lookup succeeded; either fully resolved or (QR with several packagings)
    /// waiting on the user to pick one before the confirmation sheet can show.
    case found(ScanFoundState)
    /// Camera permission is denied — the user must grant it in Settings.
    case cameraDenied
    /// The lookup failed for lack of connectivity; the same code can be retried.
    case offline(MedicineIdentifier)
    /// CIMA has no usable match; fall back to manual entry.
    case notFound
}

/// What a successful CIMA lookup yielded — either a ready confirmation model, or (the
/// QR route, when the medicine has more than one packaging) the raw choice the sheet
/// must resolve before showing one.
enum ScanFoundState: Equatable {
    case resolved(ScanConfirmationModel)
    case choosingPresentation(suggestion: MedicationLookupSuggestion, photoURL: URL?, presentations: [CIMAPresentacion])
}

/// Inputs that move the viewfinder between states.
enum ScanEvent {
    case cameraPermissionDenied
    case codeDetected(MedicineIdentifier)
    case lookupSucceeded(ScanFoundState)
    case lookupFailed(LookupError)
    /// User asked to retry after an offline failure.
    case retry
    /// User dismissed a result to scan again.
    case reset
}

extension ScanViewfinderState {
    /// Advances the viewfinder given an event, returning the next state.
    ///
    /// `codeDetected` only fires from `.scanning`, so a repeat that slips past the
    /// debouncer while a result is already on screen can't clobber it.
    func reduced(on event: ScanEvent) -> ScanViewfinderState {
        switch event {
        case .cameraPermissionDenied:
            return .cameraDenied
        case .codeDetected(let identifier):
            guard self == .scanning else { return self }
            return .looking(identifier)
        case .lookupSucceeded(let found):
            return .found(found)
        case .lookupFailed(let error):
            switch error {
            case .network:
                // Offer a retry only when we still know which code failed.
                if case .looking(let identifier) = self { return .offline(identifier) }
                return self
            case .notFound, .decoding:
                return .notFound
            }
        case .retry:
            if case .offline(let identifier) = self { return .looking(identifier) }
            return self
        case .reset:
            return .scanning
        }
    }
}
