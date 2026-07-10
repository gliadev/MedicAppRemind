//
//  ScanDebouncer.swift
//  MedicAppRemind
//
//  FX.S3 — The metadata output repeats the same code many times per second while
//  it stays in frame. This collapses that stream so a single box routes exactly
//  once. Pure value type; the bridge holds one and mutates it on its serial queue.
//

struct ScanDebouncer {
    private var lastHandled: String?

    /// `true` the first time a value is seen; `false` for immediate repeats of it.
    mutating func shouldHandle(_ value: String) -> Bool {
        guard value != lastHandled else { return false }
        lastHandled = value
        return true
    }

    /// Forgets the last value so the same code routes again — e.g. the user
    /// rescans the same box after a failed lookup.
    mutating func reset() {
        lastHandled = nil
    }
}
