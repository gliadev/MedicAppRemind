//
//  MedicationDraft+Editor.swift
//  MedicAppRemind
//
//  F10.S1 — Converts a quick-add draft into values the medication editor can
//  prefill. Defensive clamps only: an out-of-range value is dropped (the field
//  stays empty), never silently corrected. Clinical validation is NOT
//  duplicated here — the editor's save path (`Medication.validated()` /
//  `DoseSchedule.validated()`) remains the single gate before persistence.
//

import Foundation

/// Values to apply onto the open medication editor. Only present fields are
/// applied; everything else — typed values, defaults, `lowStockThresholdDays` —
/// stays exactly as the editor already has it.
struct MedicationEditorPrefill: Equatable {
    var name: String?
    var doseLabel: String?
    var pillsPerDose: Double?
    var form: MedicationForm?
    var currentStock: Double?
    var schedule: DoseSchedulePrefill?
}

/// A drafted schedule converted to Domain terms, ready to seed the editor's
/// pauta state. For `.everyNHours`, `times` holds the anchor ("primera toma");
/// empty means the editor keeps its default anchor.
struct DoseSchedulePrefill: Equatable {
    var times: [DateComponents]
    var frequency: DoseFrequency
}

extension MedicationDraft {
    /// The editor values this draft carries. Text fields are trimmed (empty →
    /// absent); numeric fields outside their sanity bounds are dropped rather
    /// than corrected; the schedule converts via `DraftSchedule.editorPrefill()`.
    func editorPrefill() -> MedicationEditorPrefill {
        MedicationEditorPrefill(
            name: Self.cleaned(name),
            doseLabel: Self.cleaned(doseLabel),
            pillsPerDose: Self.sane(pillsPerDose, minimum: 0.25, maximum: 10),
            form: form,
            currentStock: Self.sane(currentStock, minimum: 0, maximum: 10_000),
            schedule: schedule?.editorPrefill()
        )
    }

    /// Trimmed text, or `nil` when nothing printable remains.
    private static func cleaned(_ text: String?) -> String? {
        guard let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// The value when finite and inside its clinical sanity bounds, else `nil`.
    /// Bounds for `pillsPerDose` (0.25...10 of a unit) mirror the generation
    /// guide (F10.S2); stock caps at 10 000 units.
    private static func sane(_ value: Double?, minimum: Double, maximum: Double) -> Double? {
        guard let value, value.isFinite, (minimum...maximum).contains(value) else { return nil }
        return value
    }
}

extension DraftSchedule {
    /// The drafted schedule in Domain terms, or `nil` when it could never fire
    /// (no valid time for a per-day pauta, no weekday, an interval outside
    /// 1...24 h) — the editor then simply requires a pauta, as it does today.
    func editorPrefill() -> DoseSchedulePrefill? {
        let times = (timesOfDay ?? [])
            .filter { (0...23).contains($0.hour) && (0...59).contains($0.minute) }
            .map { DateComponents(hour: $0.hour, minute: $0.minute) }

        switch kind {
        case .daily:
            guard !times.isEmpty else { return nil }
            return DoseSchedulePrefill(times: times, frequency: .daily)
        case .weekdays(let days):
            // Sorted by Calendar raw value and deduplicated, matching the
            // editor's own deterministic ordering (ScheduleKind bridge).
            let sorted = Set(days).sorted { $0.rawValue < $1.rawValue }
            guard !times.isEmpty, !sorted.isEmpty else { return nil }
            return DoseSchedulePrefill(times: times, frequency: .weekdays(sorted))
        case .everyNHours(let hours):
            guard (1...24).contains(hours) else { return nil }
            return DoseSchedulePrefill(times: times, frequency: .everyNHours(hours))
        }
    }
}
