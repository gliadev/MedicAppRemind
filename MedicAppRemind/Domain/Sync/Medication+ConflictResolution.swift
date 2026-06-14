//
//  Medication+ConflictResolution.swift
//  MedicAppRemind
//
//  F7.S2 — Last-write-wins conflict resolution for CloudKit eventual
//  consistency. Pure domain function; no SwiftData, no CloudKit.
//

import Foundation

extension Medication {
    /// Resolves a sync conflict between two versions of the *same* medication
    /// using last-write-wins on `updatedAt`: the version edited more recently
    /// wins. On an exact `updatedAt` tie the local version (`self`) is kept, so
    /// re-resolving an unchanged pair never churns.
    ///
    /// Both versions must share the same `id` — they are two snapshots of one
    /// record, one held locally and one arrived from CloudKit. The
    /// `MedicationStoreActor` stamps `updatedAt = .now` on every write, which is
    /// what makes this ordering meaningful.
    func resolvingConflict(with remote: Medication) -> Medication {
        remote.updatedAt > updatedAt ? remote : self
    }
}
