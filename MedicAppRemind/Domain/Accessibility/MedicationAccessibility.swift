//
//  MedicationAccessibility.swift
//  MedicAppRemind
//
//  F6.S1 — Pure VoiceOver description for a medication row. No SwiftUI;
//  fully testable as a domain function. Combines name, dose label, remaining
//  days, and stock level into a single coherent phrase.
//

import Foundation

extension Medication {
    /// A single, coherent VoiceOver phrase for a medication list row.
    ///
    /// Examples:
    /// - "Ibuprofeno, 600 mg, quedan 30 días, stock correcto"
    /// - "Metformina, 850 mg, quedan 4 días, stock bajo"
    /// - "Atorvastatina, 20 mg, sin stock"
    /// - "Vitamina C, 500 mg, sin pauta"
    ///
    /// Delegates stock-level logic to `stockStatus(for:)` so the clinical
    /// thresholds remain a single source of truth.
    func accessibilityDescription(for schedule: DoseSchedule) -> String {
        let stock = stockStatus(for: [schedule])
        switch stock.level {
        case .unknown:
            return "\(name), \(doseLabel), sin pauta"
        case .critical:
            return "\(name), \(doseLabel), sin stock"
        case .ok:
            let days = stock.remainingDays ?? 0
            return "\(name), \(doseLabel), quedan \(days) días, stock correcto"
        case .low:
            let days = stock.remainingDays ?? 0
            return "\(name), \(doseLabel), quedan \(days) días, stock bajo"
        }
    }
}
