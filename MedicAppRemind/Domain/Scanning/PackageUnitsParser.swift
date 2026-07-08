//
//  PackageUnitsParser.swift
//  MedicAppRemind
//
//  FX.S1 — Stateless parser for the unit count embedded in a CIMA presentation
//  name ("…, 20 comprimidos" → 20). Feeds the initial-stock suggestion; when it
//  yields nil the user types the stock, so precision beats recall here.
//

import Foundation

enum PackageUnitsParser {
    /// Extracts the number of units from a CIMA presentation `nombre`.
    /// Recognised pharmaceutical forms: comprimidos, cápsulas, sobres, viales,
    /// ampollas, parches, óvulos, supositorios (singular or plural).
    static func packageUnits(fromPresentationName name: String) -> Int? {
        // Local because `Regex` is not `Sendable` and cannot back shared global state.
        let unitsRegex = #/(?<units>\d+)\s+(?:comprimidos?|c[áa]psulas?|sobres?|vial(?:es)?|ampollas?|parches?|[óo]vulos?|supositorios?)\b/#
            .ignoresCase()
        guard let match = name.firstMatch(of: unitsRegex) else { return nil }
        return Int(match.output.units)
    }
}
