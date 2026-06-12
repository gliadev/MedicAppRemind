//
//  AccessibilityDescriptionTests.swift
//  MedicAppRemindTests
//
//  F6.S1 — Smoke tests for `Medication.accessibilityDescription(for:)`.
//  Verifies that the VoiceOver phrase always includes name, dose label, and
//  remaining-days info for every stock level. Pure domain: no UI, no store.
//

import Testing
@testable import MedicAppRemind

@Suite("Medication.accessibilityDescription")
struct AccessibilityDescriptionTests {

    // Once-daily schedule at 09:00 — 1 dose/day
    private let daily = makeSchedule()

    @Test("ok — includes name, doseLabel, days, and 'stock correcto'")
    func okStock() {
        // 30 pills ÷ 1 pill/dose × 1 dose/day = 30 days
        let med = makeMedication(currentStock: 30, lowStockThresholdDays: 7)
        let description = med.accessibilityDescription(for: daily)
        #expect(description.contains(med.name))
        #expect(description.contains(med.doseLabel))
        #expect(description.contains("30"))
        #expect(description.contains("stock correcto"))
    }

    @Test("low — includes name, days, and 'stock bajo'")
    func lowStock() {
        // 5 pills ÷ 1 pill/dose × 1 dose/day = 5 days ≤ threshold 7 → low
        let med = makeMedication(currentStock: 5, lowStockThresholdDays: 7)
        let description = med.accessibilityDescription(for: daily)
        #expect(description.contains(med.name))
        #expect(description.contains("5"))
        #expect(description.contains("stock bajo"))
    }

    @Test("critical — includes name and 'sin stock'")
    func criticalStock() {
        // 0 pills → remainingDays = 0, level = .critical
        let med = makeMedication(currentStock: 0, lowStockThresholdDays: 7)
        let description = med.accessibilityDescription(for: daily)
        #expect(description.contains(med.name))
        #expect(description.contains("sin stock"))
    }

    @Test("unknown — empty times schedule produces 'sin pauta'")
    func unknownStock() {
        // No dose times → dosesPerDay = 0 → remainingDays = nil → .unknown
        let noTimes = makeSchedule(.daily, times: [])
        let med = makeMedication()
        let description = med.accessibilityDescription(for: noTimes)
        #expect(description.contains(med.name))
        #expect(description.contains("sin pauta"))
    }
}
