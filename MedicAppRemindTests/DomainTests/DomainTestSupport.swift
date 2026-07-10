//
//  DomainTestSupport.swift
//  MedicAppRemindTests
//
//  F1 — Deterministic fixtures and helpers for the domain test suite.
//  Dates are fixed; nothing here reads the wall clock.
//

import Foundation
@testable import MedicAppRemind

/// Stable identifier for medication fixtures so two fixtures compare equal by value.
/// The literal is a valid UUID, so `?? UUID()` is an unreachable fallback that
/// merely satisfies the no-force-unwrap rule.
let medicationFixtureID = UUID(uuidString: "0BADF00D-0000-0000-0000-000000000001") ?? UUID()

/// Fixed reference instant for fixtures (2001-01-01T00:00:00Z). Never the wall clock.
let domainFixtureDate = Date(timeIntervalSinceReferenceDate: 0)

/// Builds a `Medication` with sensible, overridable defaults.
///
/// Defaults describe a valid medication: 30 pills in stock, one pill per dose,
/// low-stock threshold of 7 days.
func makeMedication(
    id: UUID = medicationFixtureID,
    name: String = "Ibuprofeno",
    notes: String = "",
    form: MedicationForm = .pill,
    doseLabel: String = "600 mg",
    pillsPerDose: Double = 1,
    currentStock: Double = 30,
    lowStockThresholdDays: Int = 7,
    createdAt: Date = domainFixtureDate,
    updatedAt: Date = domainFixtureDate,
    expiryDate: Date? = nil,
    nationalCode: String? = nil
) -> Medication {
    Medication(
        id: id,
        name: name,
        notes: notes,
        form: form,
        doseLabel: doseLabel,
        pillsPerDose: pillsPerDose,
        currentStock: currentStock,
        lowStockThresholdDays: lowStockThresholdDays,
        createdAt: createdAt,
        updatedAt: updatedAt,
        expiryDate: expiryDate,
        nationalCode: nationalCode
    )
}

/// Builds a `DoseSchedule` with overridable defaults.
///
/// Default is once daily at 09:00 — i.e. one dose per day — so callers override
/// only the axis under test.
func makeSchedule(
    _ frequency: DoseFrequency = .daily,
    times: [DateComponents] = [DateComponents(hour: 9)],
    startDate: Date = domainFixtureDate,
    endDate: Date? = nil
) -> DoseSchedule {
    DoseSchedule(times: times, frequency: frequency, startDate: startDate, endDate: endDate)
}

/// Encodes then decodes a value through JSON, returning the reconstructed value.
/// Lets a test assert that a round-trip preserves equality.
func roundTripJSON<T: Codable>(_ value: T) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}
