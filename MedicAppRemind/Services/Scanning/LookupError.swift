//
//  LookupError.swift
//  MedicAppRemind
//
//  FX.S2 — Failures surfaced by CIMAService. `LocalizedError` already refines
//  `Error`. Every case degrades to manual entry in the UI, never a dead end.
//

import Foundation

enum LookupError: LocalizedError {
    /// No match for the CN/nregistro (CIMA returns a non-200 status or an empty body).
    case notFound
    /// The request itself failed (no connectivity, timeout…).
    case network
    /// CIMA responded but the body isn't the JSON shape expected.
    case decoding

    var errorDescription: String? {
        switch self {
        case .notFound:
            String(localized: "No se ha encontrado ningún medicamento con ese código. Puedes introducir los datos manualmente.")
        case .network:
            String(localized: "No hay conexión con CIMA. Comprueba tu red e inténtalo de nuevo.")
        case .decoding:
            String(localized: "CIMA ha devuelto una respuesta inesperada. Inténtalo de nuevo o introduce los datos manualmente.")
        }
    }
}
