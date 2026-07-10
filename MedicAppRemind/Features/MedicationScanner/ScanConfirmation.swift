//
//  ScanConfirmation.swift
//  MedicAppRemind
//
//  FX.S5 — What the confirmation sheet shows and offers, decided purely from CIMA's
//  suggestion, the parsed box and the store's dedup preview (FX.S4's read-only
//  `previewScanMerge`). No actor calls, no writes — building this never mutates
//  anything, so the sheet can always show it before the user commits to an action.
//

import Foundation

/// The action "Usar datos" performs once the user confirms.
enum ScanConfirmationAction: Equatable, Sendable {
    /// No medication with this box's national code exists yet — prefills the open
    /// editor; nothing is written until the user taps "Guardar" there.
    case create
    /// This national code matches an existing medication and the box's serial is new —
    /// adds the box's units to its stock directly.
    case addStock(medicationID: UUID, medicationName: String)
    /// This exact box (same serial) was already scanned — nothing left to confirm.
    case duplicateBox(medicationName: String)
}

/// The confirmation sheet's presentation model for one resolved box.
struct ScanConfirmationModel: Equatable, Sendable {
    var nombre: String
    var dosis: String?
    var expiryDate: Date?
    var units: Int?
    var nationalCode: String
    var serial: String?
    var photoURL: URL?
    var action: ScanConfirmationAction
    /// The dose field is empty because CIMA reported more than one active ingredient —
    /// shown blank and flagged in the sheet, never guessed.
    var doseNeedsUserInput: Bool
}

/// Builds the confirmation model for a resolved box. `preview.decision` and
/// `preview.medicationID`/`medicationName` always agree by construction (the actor
/// names the match whenever it isn't `.create`); the `.addStock` branch still degrades
/// to `.create` if they don't, rather than force-unwrapping.
func scanConfirmation(
    suggestion: MedicationLookupSuggestion,
    box: ScannedBox,
    preview: ScanMergePreview,
    photoURL: URL? = nil
) -> ScanConfirmationModel {
    let action: ScanConfirmationAction
    switch preview.decision {
    case .create:
        action = .create
    case .addStock:
        if let id = preview.medicationID, let name = preview.medicationName {
            action = .addStock(medicationID: id, medicationName: name)
        } else {
            action = .create
        }
    case .duplicateBox:
        action = .duplicateBox(medicationName: preview.medicationName ?? "")
    }
    return ScanConfirmationModel(
        nombre: suggestion.nombre,
        dosis: suggestion.dosis,
        expiryDate: box.expiry,
        units: box.units,
        nationalCode: box.nationalCode,
        serial: box.serial,
        photoURL: photoURL,
        action: action,
        doseNeedsUserInput: suggestion.dosis == nil
    )
}

/// What confirming a scan hands back to whoever presented the scanner (the medication
/// editor, FX.S5). `.addStock` has already been written by the time this fires — the
/// sheet only offers it, the screen performs the merge on confirm.
enum ScanOutcome: Equatable, Sendable {
    case prefill(name: String, dosis: String?, expiryDate: Date?, units: Int?, nationalCode: String)
    case stockAdded(medicationName: String, units: Int?)
}
