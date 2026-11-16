//
//  GeneratedMedicationDraft.swift
//  MedicAppRemind
//
//  F10.S2 — @Generable mirror of the Domain's MedicationDraft. This is the
//  only shape the model ever fills in; Domain types stay free of
//  FoundationModels. Guide descriptions are code, not UI — English on purpose.
//  Every field is optional: the model must omit what the text doesn't say.
//

import Foundation
import FoundationModels

@Generable(description: "Structured data about one medication, extracted from a person's free-text description")
struct GeneratedMedicationDraft {
    @Guide(description: "The medication name only, without strength or dosage, exactly as mentioned. Omit if no medication is named.")
    var name: String?

    @Guide(description: "The dose strength exactly as written, for example '600 mg'. Omit if not mentioned.")
    var doseLabel: String?

    @Guide(description: "Units (pills, capsules, measures) taken per single dose. Omit if not mentioned.", .range(0.25...10.0))
    var pillsPerDose: Double?

    @Guide(description: "The physical form of the medication. Omit if not mentioned.")
    var form: GeneratedMedicationForm?

    @Guide(description: "Units the person says they currently have in stock. Omit if not mentioned.", .range(0.0...10_000.0))
    var currentStock: Double?

    @Guide(description: "The dosing schedule. Omit if the text mentions no schedule.")
    var schedule: GeneratedSchedule?
}

@Generable(description: "The physical form of a medication")
enum GeneratedMedicationForm {
    case pill
    case capsule
    case tablet
    case liquid
    case injection
    case other
}

@Generable(description: "When and how often the medication is taken")
struct GeneratedSchedule {
    @Guide(description: "Times of day explicitly mentioned. Omit if none are mentioned.")
    var timesOfDay: [GeneratedTime]?

    @Guide(description: "How the doses repeat across days")
    var kind: GeneratedFrequencyKind

    @Guide(description: "Hours between doses, only when kind is everyNHours.", .range(1...24))
    var intervalHours: Int?

    @Guide(description: "Days of the week, only when kind is weekdays.")
    var weekdays: [GeneratedWeekday]?
}

@Generable(description: "How doses repeat across days")
enum GeneratedFrequencyKind {
    case daily
    case everyNHours
    case weekdays
}

@Generable(description: "A time of day on the 24-hour clock")
struct GeneratedTime {
    @Guide(description: "Hour of day", .range(0...23))
    var hour: Int

    @Guide(description: "Minute of the hour", .range(0...59))
    var minute: Int
}

@Generable(description: "A day of the week")
enum GeneratedWeekday {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

// MARK: - Pure mapping onto the Domain draft

extension GeneratedMedicationDraft {
    /// The Domain draft this generation represents. Purely mechanical: nils
    /// stay nil, and the S1 conversion keeps all defensive clamping — nothing
    /// clinical is decided here.
    func toDomainDraft(sourceText: String) -> MedicationDraft {
        MedicationDraft(
            name: name,
            doseLabel: doseLabel,
            pillsPerDose: pillsPerDose,
            form: form?.toDomainForm(),
            currentStock: currentStock,
            schedule: schedule?.toDomainSchedule(),
            sourceText: sourceText
        )
    }
}

extension GeneratedSchedule {
    /// The drafted schedule, or `nil` when the generation is unusable (an
    /// interval kind without an interval value) — never invented.
    func toDomainSchedule() -> DraftSchedule? {
        let times = timesOfDay?.map { DraftTime(hour: $0.hour, minute: $0.minute) }
        switch kind {
        case .daily:
            return DraftSchedule(timesOfDay: times, kind: .daily)
        case .everyNHours:
            guard let intervalHours else { return nil }
            return DraftSchedule(timesOfDay: times, kind: .everyNHours(intervalHours))
        case .weekdays:
            let days = (weekdays ?? []).map { $0.toDomainWeekday() }
            return DraftSchedule(timesOfDay: times, kind: .weekdays(days))
        }
    }
}

extension GeneratedMedicationForm {
    func toDomainForm() -> MedicationForm {
        switch self {
        case .pill:      .pill
        case .capsule:   .capsule
        case .tablet:    .tablet
        case .liquid:    .liquid
        case .injection: .injection
        case .other:     .other
        }
    }
}

extension GeneratedWeekday {
    func toDomainWeekday() -> Weekday {
        switch self {
        case .sunday:    .sunday
        case .monday:    .monday
        case .tuesday:   .tuesday
        case .wednesday: .wednesday
        case .thursday:  .thursday
        case .friday:    .friday
        case .saturday:  .saturday
        }
    }
}
