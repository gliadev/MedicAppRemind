//
//  DosePayload.swift
//  MedicAppRemind
//
//  F3.S3 — The single source of truth for the `userInfo` a dose notification
//  carries. NotificationService writes it when scheduling; the delegate reads it
//  back to deep-link or act. Keeping the key and its parsing in one type means
//  producer and consumer can never drift.
//

import Foundation

/// The data a dose notification carries in `userInfo`: which medication it is for.
///
/// `init?(userInfo:)` returns `nil` for a missing or malformed id rather than
/// trapping, so a stray notification degrades to "ignore" instead of crashing.
struct DosePayload: Equatable, Sendable {
    /// The `userInfo` key under which the medication id is stored.
    static let medicationIDKey = "medicationID"

    var medicationID: UUID

    init(medicationID: UUID) {
        self.medicationID = medicationID
    }

    /// Parses the payload from a delivered notification's `userInfo`, or `nil`
    /// when the medication id is absent or not a valid UUID string.
    init?(userInfo: [AnyHashable: Any]) {
        guard let raw = userInfo[Self.medicationIDKey] as? String,
              let id = UUID(uuidString: raw) else {
            return nil
        }
        medicationID = id
    }

    /// The `userInfo` dictionary to attach to a notification's content.
    var userInfo: [String: String] {
        [Self.medicationIDKey: medicationID.uuidString]
    }
}
