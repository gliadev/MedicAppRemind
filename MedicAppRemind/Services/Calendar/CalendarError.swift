//
//  CalendarError.swift
//  MedicAppRemind
//
//  F4.S1 — Degradable failures from CalendarService. The app keeps working without
//  calendar access; the UI shows the localized message instead of crashing.
//

import Foundation

/// Failures surfaced by `CalendarService`. `LocalizedError` already refines `Error`.
enum CalendarError: LocalizedError {
    /// Full calendar access is not granted.
    case accessDenied
    /// EventKit failed to save or remove an event.
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return String(localized: "No hay acceso al calendario. Actívalo en Ajustes para añadir tus tomas.")
        case .saveFailed:
            return String(localized: "No se pudo guardar el evento en el calendario. Inténtalo de nuevo.")
        }
    }
}
