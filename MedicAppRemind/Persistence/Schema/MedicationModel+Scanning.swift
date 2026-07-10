//
//  MedicationModel+Scanning.swift
//  MedicAppRemind
//
//  FX.S4 — Decoded access to the serials of boxes already scanned into a medication.
//  The raw column is `Data?` (CloudKit-safe); this projects it as `[String]` so the
//  store actor never juggles JSON, and appends idempotently for scan dedup.
//

import Foundation

extension MedicationModel {
    /// The serials of boxes already scanned into this medication, decoded from
    /// `scannedSerialsData`. A missing or corrupted payload reads as empty rather than
    /// failing. Assigning an empty array clears the column back to `nil`.
    var scannedSerials: [String] {
        get {
            guard let scannedSerialsData else { return [] }
            return (try? JSONDecoder().decode([String].self, from: scannedSerialsData)) ?? []
        }
        set {
            scannedSerialsData = newValue.isEmpty ? nil : try? JSONEncoder().encode(newValue)
        }
    }

    /// Records a scanned box's serial, skipping one already present so re-scanning the
    /// same box never grows the list — the persistence side of scan idempotency.
    func appendScannedSerial(_ serial: String) {
        var serials = scannedSerials
        guard !serials.contains(serial) else { return }
        serials.append(serial)
        scannedSerials = serials
    }
}
