//
//  MedicationModel+Calendar.swift
//  MedicAppRemind
//
//  F4.S2 — Decoded access to the calendar event identifiers mirrored for a medication.
//  The raw column is `Data?` (CloudKit-safe); this projects it as `[String]` so the
//  store actor and reconciliation never juggle JSON.
//

import Foundation

extension MedicationModel {
    /// The calendar `eventIdentifier`s mirrored for this medication, decoded from
    /// `calendarEventIDsData`. A missing or corrupted payload reads as empty rather
    /// than failing — losing track of identifiers must never crash. Assigning an empty
    /// array clears the column back to `nil`.
    var calendarEventIDs: [String] {
        get {
            guard let calendarEventIDsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: calendarEventIDsData)) ?? []
        }
        set {
            calendarEventIDsData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }
}
