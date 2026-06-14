//
//  SchemaCloudKitSafetyTests.swift
//  MedicAppRemindTests
//
//  F7.S1 — The guardian of the CloudKit-safe rule. Reflects over the production
//  schema and fails if any @Model reintroduces a uniqueness constraint
//  (@Attribute(.unique)/#Unique) or a non-optional relationship — the two
//  constructs CloudKit forbids. Pure schema reflection: no container, no disk,
//  no network. Builds the same Schema PersistenceController uses in production.
//

import Testing
import Foundation
import SwiftData
@testable import MedicAppRemind

@Suite("Schema CloudKit safety")
struct SchemaCloudKitSafetyTests {

    /// The production schema, built exactly as `PersistenceController` builds it.
    private let schema = Schema(versionedSchema: MedicineSchemaV1.self)

    @Test("No entity declares a uniqueness constraint")
    func noUniquenessConstraints() {
        for entity in schema.entities {
            #expect(
                entity.uniquenessConstraints.isEmpty,
                "\(entity.name) declares uniqueness constraints \(entity.uniquenessConstraints); CloudKit forbids #Unique."
            )
        }
    }

    @Test("No attribute is marked unique")
    func noUniqueAttributes() {
        for entity in schema.entities {
            for attribute in entity.attributes {
                #expect(
                    !attribute.isUnique,
                    "\(entity.name).\(attribute.name) is marked unique; CloudKit forbids @Attribute(.unique)."
                )
            }
        }
    }

    @Test("Every relationship is optional")
    func allRelationshipsOptional() {
        for entity in schema.entities {
            for relationship in entity.relationships {
                #expect(
                    relationship.isOptional,
                    "\(entity.name).\(relationship.name) is a non-optional relationship; CloudKit requires optional relationships."
                )
            }
        }
    }

    @Test("Schema contains exactly the three expected entities")
    func schemaHasExpectedEntities() {
        let names = Set(schema.entities.map(\.name))
        #expect(names == ["MedicationModel", "DoseScheduleModel", "IntakeLogModel"])
    }
}
