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
    ///
    /// `locale` drives which localization is looked up (via
    /// `LocalizedStringResource.locale`), so tests can pin a language
    /// deterministically; production omits it and follows the user's locale.
    func doseRegisteredAnnouncement(
        remainingAfter remaining: Double,
        locale: Locale = .current
    ) -> String {
        let count = Int(max(0, remaining))
        let pills = pillCountText(Double(count), locale: locale)
        var resource: LocalizedStringResource = "Toma registrada, quedan \(pills)"
        resource.locale = locale
        return String(localized: resource)
    }
}
