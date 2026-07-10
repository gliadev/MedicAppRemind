//
//  MedicationModel+Mapping.swift
//  MedicAppRemind
//
//  F2.S1 — Mapping between the `MedicationModel` record and the `Medication`
//  domain value type. The actor (F2.S2) exposes domain types only.
//

import Foundation

extension MedicationModel {
    /// Projects the record into its pure domain value.
    ///
    /// An unknown `formRaw` falls back to `.other` rather than failing — a record
    /// written by a newer version must still be readable, never a hard error.
    func toDomain() -> Medication {
        Medication(
            id: id,
            name: name,
            notes: notes,
            form: MedicationForm(rawValue: formRaw) ?? .other,
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

    /// Copies the domain value's scalar fields onto the record. Relationships
    /// (`schedules`, `intakeLogs`) are wired by the actor, not here.
    func apply(_ medication: Medication) {
        id = medication.id
        name = medication.name
        notes = medication.notes
        formRaw = medication.form.rawValue
        doseLabel = medication.doseLabel
        pillsPerDose = medication.pillsPerDose
        currentStock = medication.currentStock
        lowStockThresholdDays = medication.lowStockThresholdDays
        createdAt = medication.createdAt
        updatedAt = medication.updatedAt
        expiryDate = medication.expiryDate
        nationalCode = medication.nationalCode
    }
}
