//
//  ScannedMedication.swift
//  MedicAppRemind
//
//  v1.2 — Pure parser for the medication scanner. Turns the raw text lines a live OCR
//  scan recognises on a medication box into a best-effort name + dose to prefill the
//  editor. Heuristic by nature (boxes vary wildly), so it only *suggests* — the user
//  always reviews. Kept free of VisionKit so the logic is unit-testable on its own.
//

import Foundation

/// A best-effort medication identity extracted from scanned text. Both fields are
/// optional: a scan may catch a name, a dose, both, or neither.
struct ScannedMedication: Equatable {
    var name: String?
    var dose: String?

    /// Empty when neither field was recognised — the caller can ignore such a scan.
    var isEmpty: Bool { name == nil && dose == nil }
}

extension ScannedMedication {
    /// Builds a suggestion from the OCR transcript lines (in reading order).
    ///
    /// - dose: the first quantity+unit found across all lines, normalised to a single
    ///   space ("875mg" → "875 mg").
    /// - name: the first line that still has letters once any dose is stripped out, so a
    ///   combined "Ibuprofeno 600 mg" yields "Ibuprofeno" and a lone "500 mg" is skipped.
    init(recognizedLines lines: [String]) {
        // Quantity + unit, e.g. "500 mg", "0,5 ml", "875mg". Longer units come first in the
        // alternation so "500mg" binds to `mg`, never the bare `g`. Local (not a static let)
        // because `Regex` is not `Sendable` and cannot back shared global state.
        let doseRegex = #/(?<number>\d+(?:[.,]\d+)?)\s*(?<unit>mcg|µg|mg|ml|UI|g|%)/#
            .ignoresCase()

        let trimmed = lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var foundDose: String?
        for line in trimmed {
            if let match = line.firstMatch(of: doseRegex) {
                foundDose = "\(match.output.number) \(match.output.unit)"
                break
            }
        }

        var foundName: String?
        for line in trimmed {
            let withoutDose = line.replacing(doseRegex, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if withoutDose.contains(where: \.isLetter) {
                foundName = withoutDose
                break
            }
        }

        self.init(name: foundName, dose: foundDose)
    }
}
