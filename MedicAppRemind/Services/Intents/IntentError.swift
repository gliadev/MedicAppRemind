//
//  IntentError.swift
//  MedicAppRemind
//
//  F5.S2 — Errors surfaced by the App Intents. Conforms to
//  `CustomLocalizedStringResourceConvertible` so the system speaks a localized
//  message instead of a generic failure.
//

import AppIntents
import Foundation

/// A failure an intent can report to the user. The entity query usually resolves a
/// real medication before `perform()` runs, so `medicationNotFound` is the rare
/// race where it was deleted in between, or the shared store couldn't be opened.
enum IntentError: Error, Equatable, CustomLocalizedStringResourceConvertible {
    case medicationNotFound

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .medicationNotFound:
            "No encontré ese medicamento. Vuelve a intentarlo desde la app."
        }
    }
}
