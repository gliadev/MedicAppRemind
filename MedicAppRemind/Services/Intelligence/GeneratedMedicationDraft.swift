//
//  GeneratedMedicationDraft.swift
//  MedicAppRemind
//
//  F10.S2 — Mirror of the Domain's MedicationDraft, decoded from the model's
//  plain-text JSON response. It was @Generable guided generation until the
//  2026-11-16 spike proved guided generation always hits default guardrails
//  with medication text; only String responses honor the permissive mode
//  (see ADR05). Decoding is tolerant: an unrecognizable field is dropped,
//  never invented, and never breaks the rest of the draft.
//

import Foundation

struct GeneratedMedicationDraft {
    var name: String?
    var doseLabel: String?
    var pillsPerDose: Double?
    var form: GeneratedMedicationForm?
    var currentStock: Double?
    var schedule: GeneratedSchedule?
}

enum GeneratedMedicationForm {
    case pill
    case capsule
    case tablet
    case liquid
    case injection
    case other
}

struct GeneratedSchedule {
    var timesOfDay: [GeneratedTime]?
    var kind: GeneratedFrequencyKind
    var intervalHours: Int?
    var weekdays: [GeneratedWeekday]?
}

enum GeneratedFrequencyKind {
    case daily
    case everyNHours
    case weekdays
}

struct GeneratedTime: Decodable {
    var hour: Int
    var minute: Int
}

enum GeneratedWeekday {
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday
}

// MARK: - Decoding the model's text output

extension GeneratedMedicationDraft: Decodable {

    /// The whole draft decoded from the model's raw text response. The model
    /// is instructed to answer with bare JSON but routinely adds code fences
    /// or prose, so the object is extracted between the outermost braces.
    static func decode(fromModelOutput output: String) throws -> GeneratedMedicationDraft {
        guard let start = output.firstIndex(of: "{"),
              let end = output.lastIndex(of: "}"),
              start <= end else {
            throw DraftParserError.couldNotParse
        }
        let data = Data(output[start...end].utf8)
        return try JSONDecoder().decode(GeneratedMedicationDraft.self, from: data)
    }

    /// A draft with no extracted field at all — the parser treats it as the
    /// single failure path ("the text does not describe a medication").
    var isEmpty: Bool {
        name == nil && doseLabel == nil && pillsPerDose == nil
            && form == nil && currentStock == nil && schedule == nil
    }

    private enum CodingKeys: String, CodingKey {
        case name, doseLabel, pillsPerDose, form, currentStock
        case frequencyKind, everyNHours, weekdays, timesOfDay
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? container.decodeIfPresent(String.self, forKey: .name)) ?? nil
        doseLabel = (try? container.decodeIfPresent(String.self, forKey: .doseLabel)) ?? nil
        pillsPerDose = (try? container.decodeIfPresent(Double.self, forKey: .pillsPerDose)) ?? nil
        currentStock = (try? container.decodeIfPresent(Double.self, forKey: .currentStock)) ?? nil

        let formName = (try? container.decodeIfPresent(String.self, forKey: .form)) ?? nil
        form = formName.flatMap(GeneratedMedicationForm.init(tolerant:))

        let kindName = (try? container.decodeIfPresent(String.self, forKey: .frequencyKind)) ?? nil
        let interval = (try? container.decodeIfPresent(Int.self, forKey: .everyNHours)) ?? nil
        let dayNames = (try? container.decodeIfPresent([String].self, forKey: .weekdays)) ?? nil
        let times = (try? container.decodeIfPresent([GeneratedTime].self, forKey: .timesOfDay)) ?? nil

        if let kind = kindName.flatMap(GeneratedFrequencyKind.init(tolerant:)) {
            schedule = GeneratedSchedule(
                timesOfDay: times,
                kind: kind,
                intervalHours: interval,
                weekdays: dayNames.map { $0.compactMap(GeneratedWeekday.init(tolerant:)) }
            )
        } else {
            // Unknown or missing frequency (the spike saw "weekly"): dropping
            // the schedule keeps the rest of the draft usable — never guessed.
            schedule = nil
        }
    }
}

// MARK: - Tolerant token parsing (ES + EN, accent- and case-insensitive)

private extension String {
    var normalizedToken: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "es_ES"))
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension GeneratedFrequencyKind {
    init?(tolerant name: String) {
        switch name.normalizedToken {
        case "daily":       self = .daily
        case "everynhours": self = .everyNHours
        case "weekdays":    self = .weekdays
        default:            return nil
        }
    }
}

extension GeneratedWeekday {
    init?(tolerant name: String) {
        switch name.normalizedToken {
        case "monday", "lunes":        self = .monday
        case "tuesday", "martes":      self = .tuesday
        case "wednesday", "miercoles": self = .wednesday
        case "thursday", "jueves":     self = .thursday
        case "friday", "viernes":      self = .friday
        case "saturday", "sabado":     self = .saturday
        case "sunday", "domingo":      self = .sunday
        default:                       return nil
        }
    }
}

extension GeneratedMedicationForm {
    init?(tolerant name: String) {
        switch name.normalizedToken {
        case "pill", "pastilla":        self = .pill
        case "capsule", "capsula":      self = .capsule
        case "tablet", "comprimido":    self = .tablet
        case "liquid", "liquido", "jarabe": self = .liquid
        case "injection", "inyeccion":  self = .injection
        case "other", "otro", "otra":   self = .other
        default:                        return nil
        }
    }
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
