//
//  ScanMerge.swift
//  MedicAppRemind
//
//  FX.S4 — Merging a freshly scanned box into the store, in pure value form. The
//  reducer decides create / add-stock / duplicate from the box and the store's current
//  state; the actor (persistence) turns the decision into a write. No SwiftData here.
//

import Foundation

/// A scanned box resolved for merging: its national code, the box's serial (for dedup),
/// the units per package (from CIMA, `nil` when unknown) and the parsed expiry.
struct ScannedBox: Equatable, Sendable {
    var nationalCode: String
    var serial: String?
    var units: Int?
    var expiry: Date?
}

/// The serials already recorded for the medication a scan matches, or the whole value is
/// `nil` when no medication matches the scanned national code.
struct StoredBoxState: Equatable, Sendable {
    var recordedSerials: Set<String>

    init(recordedSerials: Set<String> = []) {
        self.recordedSerials = recordedSerials
    }
}

/// What merging a scanned box against the store implies.
enum ScanMergeDecision: Equatable, Sendable {
    /// No medication with the scanned national code exists yet — create one, seeding its
    /// stock with the box's units (`nil` when CIMA didn't report a package size, so the
    /// user types it).
    case create(units: Int?)
    /// The medication exists and this box is new — add the box's units to its stock.
    case addStock(units: Int?)
    /// This exact box was already scanned (same serial) — a no-op, so re-scanning never
    /// double-counts stock.
    case duplicateBox
}

/// A read-only preview of `scanMergeDecision`, naming the medication a national code
/// already matches (if any) — what the confirmation sheet (FX.S5) shows before the user
/// commits. `medicationID`/`medicationName` are `nil` exactly when `decision == .create`.
struct ScanMergePreview: Equatable, Sendable {
    var decision: ScanMergeDecision
    var medicationID: UUID?
    var medicationName: String?
}

/// Decides how a scanned box merges into the store: a new national code creates, a new
/// serial on a known medication adds stock, an already-recorded serial is a duplicate.
///
/// A box without a serial (an OTC EAN-13) can't be deduplicated, so on a known medication
/// it always adds stock.
func scanMergeDecision(serial: String?, units: Int?, against stored: StoredBoxState?) -> ScanMergeDecision {
    guard let stored else { return .create(units: units) }
    if let serial, stored.recordedSerials.contains(serial) {
        return .duplicateBox
    }
    return .addStock(units: units)
}

extension Medication {
    /// The nearest expiry between the stored date and a freshly scanned one — the box that
    /// expires first governs the alert. A missing date on either side is ignored; `nil`
    /// only when neither is known.
    func mergedExpiry(with scanned: Date?) -> Date? {
        [expiryDate, scanned].compactMap { $0 }.min()
    }
}
