//
//  MedicationStoreActor+ScanMerge.swift
//  MedicAppRemind
//
//  FX.S4 — Persists a scanned box against the store. The decision is pure (scanMergeDecision);
//  this turns an `.addStock` into a single save, idempotent by serial. Creation of a brand-new
//  medication is left to the confirmation sheet (FX.S5); here `.create`/`.duplicateBox` write
//  nothing. Only domain value types cross the actor boundary.
//

import Foundation
import SwiftData

extension MedicationStoreActor {
    /// Merges a scanned box into the medication matching its national code: adds the box's
    /// units to stock, records its serial and pulls the stored expiry to the nearer of the
    /// two. Idempotent by serial — re-merging the same box returns `.duplicateBox` and
    /// writes nothing. An unknown national code returns `.create` (the sheet builds the new
    /// medication in FX.S5) without touching the store.
    func applyScanMerge(_ box: ScannedBox) throws -> ScanMergeDecision {
        let model = try existingMedication(nationalCode: box.nationalCode)
        let stored = model.map { StoredBoxState(recordedSerials: Set($0.scannedSerials)) }
        let decision = scanMergeDecision(serial: box.serial, units: box.units, against: stored)

        guard case .addStock(let units) = decision, let model else { return decision }
        if let units { model.currentStock += Double(units) }
        if let serial = box.serial { model.appendScannedSerial(serial) }
        model.expiryDate = model.toDomain().mergedExpiry(with: box.expiry)
        model.updatedAt = .now
        try modelContext.save()
        return decision
    }

    /// Read-only preview of how a scanned box would merge, without writing — what the
    /// confirmation sheet (FX.S5) shows before the user taps "Usar datos". Mirrors
    /// `applyScanMerge`'s decision (`units` doesn't affect which case is chosen, so it's
    /// omitted here; the sheet already has it from the scan/CIMA lookup).
    func previewScanMerge(nationalCode: String, serial: String?) throws -> ScanMergePreview {
        let model = try existingMedication(nationalCode: nationalCode)
        let stored = model.map { StoredBoxState(recordedSerials: Set($0.scannedSerials)) }
        let decision = scanMergeDecision(serial: serial, units: nil, against: stored)
        return ScanMergePreview(decision: decision, medicationID: model?.id, medicationName: model?.name)
    }

    /// The serials of boxes already scanned into this medication (FX.S4), or `[]` when it
    /// has none or the medication is unknown.
    func scannedSerials(medicationID: UUID) throws -> [String] {
        var descriptor = FetchDescriptor<MedicationModel>(predicate: #Predicate { $0.id == medicationID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.scannedSerials ?? []
    }

    // MARK: - Helpers

    /// The medication carrying this national code, or `nil` when none does. Logical match
    /// only — CloudKit forbids `@Attribute(.unique)`, so uniqueness is a store invariant.
    private func existingMedication(nationalCode: String) throws -> MedicationModel? {
        let target: String? = nationalCode
        var descriptor = FetchDescriptor<MedicationModel>(
            predicate: #Predicate { $0.nationalCode == target }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }
}
