//
//  MedicationDetailAccessibility.swift
//  MedicAppRemind
//
//  F6.S2 — Pure VoiceOver announcement produced after a dose is recorded.
//  No SwiftUI; fully unit-testable as a domain function.
//

import Foundation

extension Medication {
    /// VoiceOver announcement text after successfully recording a dose.
    ///
    /// `remaining` is the new stock count (post-decrement); clamped to zero
    /// because stock is never negative.
    func doseRegisteredAnnouncement(remainingAfter remaining: Double) -> String {
        let count = Int(max(0, remaining))
        return String(localized: "Toma registrada, quedan \(count) pastillas")
    }
}
