//
//  MedicationEntity.swift
//  MedicAppRemind
//
//  F5.S1 — The bridge between the app's domain and Siri/Shortcuts. A
//  `MedicationEntity` is how the system refers to "the ibuprofen" or "the
//  metformin" when resolving an intent's `@Parameter`. It carries only the
//  fields the system needs — identity, name, dose label — never a `@Model`.
//

import AppIntents
import Foundation

/// A medication as the system sees it: a stable identifier plus the human-readable
/// name and dose label Siri reads back. Projected from the domain `Medication`;
/// resolved through `MedicationEntityQuery`.
struct MedicationEntity: AppEntity, Equatable {
    let id: UUID
    let name: String
    let doseLabel: String

    /// How the system names this *type* of entity in Shortcuts ("Medicamento").
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Medicamento"

    /// How a single entity is shown: the medication name as title, the dose label
    /// as subtitle, so VoiceOver reads both and the two never blur into one string.
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(doseLabel)")
    }

    /// The query the system uses to resolve entities by id and to suggest options.
    static let defaultQuery = MedicationEntityQuery()

    /// Projects a domain `Medication` to its entity, copying only the fields the
    /// system needs. Keeps SwiftData and the domain out of the App Intents layer.
    init(_ medication: Medication) {
        self.id = medication.id
        self.name = medication.name
        self.doseLabel = medication.doseLabel
    }
}
