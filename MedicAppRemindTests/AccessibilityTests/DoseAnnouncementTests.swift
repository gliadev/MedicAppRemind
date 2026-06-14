//
//  DoseAnnouncementTests.swift
//  MedicAppRemindTests
//
//  F6.S2 — Smoke tests for `Medication.doseRegisteredAnnouncement(remainingAfter:)`.
//  Verifies the VoiceOver announcement always contains "Toma registrada" and
//  the correct rounded-down count.
//

import Foundation
import Testing
@testable import MedicAppRemind

@Suite("Medication.doseRegisteredAnnouncement")
struct DoseAnnouncementTests {

    @Test("Text starts with 'Toma registrada' when localized in Spanish")
    func prefixPresent() {
        let text = makeMedication().doseRegisteredAnnouncement(
            remainingAfter: 5,
            locale: Locale(identifier: "es")
        )
        #expect(text.hasPrefix("Toma registrada"))
    }

    @Test("Remaining count appears in text")
    func countInText() {
        let text = makeMedication().doseRegisteredAnnouncement(remainingAfter: 12)
        #expect(text.contains("12"))
    }

    @Test("Negative remaining clamped to 0 — no minus sign in output")
    func negativeClampedToZero() {
        let text = makeMedication().doseRegisteredAnnouncement(remainingAfter: -3)
        #expect(text.contains("0"))
        #expect(!text.contains("-"))
    }

    @Test("Fractional remaining floored to whole number")
    func fractionalIsFloored() {
        // 4.9 → floor → 4
        let text = makeMedication().doseRegisteredAnnouncement(remainingAfter: 4.9)
        #expect(text.contains("4"))
        #expect(!text.contains("5"))
    }

    @Test("Zero remaining produces zero in text")
    func zeroRemaining() {
        let text = makeMedication().doseRegisteredAnnouncement(remainingAfter: 0)
        #expect(text.contains("0"))
    }
}
