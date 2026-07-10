//
//  ScanConfirmationTests.swift
//  MedicAppRemindTests
//
//  FX.S5 — The confirmation sheet's presentation model is a pure function of the
//  CIMA suggestion, the parsed box and the store's dedup preview. Every test fixes
//  those three inputs and asserts a hand-computed model — no actor, no UI.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ScanConfirmation")
struct ScanConfirmationTests {

    private let existingID = UUID(uuidString: "0BADF00D-0000-0000-0000-000000000009") ?? UUID()

    private func suggestion(nombre: String = "PARACETAMOL CINFA 1 g", dosis: String? = "1000 mg") -> MedicationLookupSuggestion {
        MedicationLookupSuggestion(cimaMedicamento: CIMAMedicamento(
            nregistro: "70310",
            nombre: nombre,
            dosis: dosis,
            labtitular: nil,
            receta: nil,
            principiosActivos: dosis == nil ? [
                .init(nombre: "AMOXICILINA", cantidad: "875", unidad: "mg"),
                .init(nombre: "CLAVULANICO", cantidad: "125", unidad: "mg")
            ] : [.init(nombre: "PARACETAMOL", cantidad: "1000", unidad: "mg")]
        ))
    }

    @Test("An unknown national code carries create through, with the scanned fields")
    func createCarriesFieldsThrough() throws {
        let expiry = Date(timeIntervalSinceReferenceDate: 0)
        let box = ScannedBox(nationalCode: "662025", serial: "SN-1", units: 20, expiry: expiry)
        let preview = ScanMergePreview(decision: .create(units: 20), medicationID: nil, medicationName: nil)

        let model = scanConfirmation(suggestion: suggestion(), box: box, preview: preview)

        #expect(model.nombre == "PARACETAMOL CINFA 1 g")
        #expect(model.dosis == "1000 mg")
        #expect(model.expiryDate == expiry)
        #expect(model.units == 20)
        #expect(model.nationalCode == "662025")
        #expect(model.action == .create)
        #expect(model.doseNeedsUserInput == false)
    }

    @Test("A known national code with a new serial offers to add stock, naming the medication")
    func addStockNamesTheExistingMedication() throws {
        let box = ScannedBox(nationalCode: "662025", serial: "SN-2", units: 20, expiry: nil)
        let preview = ScanMergePreview(decision: .addStock(units: 20), medicationID: existingID, medicationName: "Paracetamol")

        let model = scanConfirmation(suggestion: suggestion(), box: box, preview: preview)

        #expect(model.action == .addStock(medicationID: existingID, medicationName: "Paracetamol"))
    }

    @Test("An already-recorded serial offers nothing but the duplicate notice")
    func duplicateNamesTheExistingMedication() throws {
        let box = ScannedBox(nationalCode: "662025", serial: "SN-1", units: 20, expiry: nil)
        let preview = ScanMergePreview(decision: .duplicateBox, medicationID: existingID, medicationName: "Paracetamol")

        let model = scanConfirmation(suggestion: suggestion(), box: box, preview: preview)

        #expect(model.action == .duplicateBox(medicationName: "Paracetamol"))
    }

    @Test("Multiple active ingredients flag the dose field as needing user input, never a guess")
    func multiPAFlagsDoseNeedsUserInput() throws {
        let box = ScannedBox(nationalCode: "694759", serial: "SN-1", units: 20, expiry: nil)
        let preview = ScanMergePreview(decision: .create(units: 20), medicationID: nil, medicationName: nil)

        let model = scanConfirmation(suggestion: suggestion(dosis: nil), box: box, preview: preview)

        #expect(model.dosis == nil)
        #expect(model.doseNeedsUserInput == true)
    }

    @Test("A missing units count carries through as nil — the user types the stock")
    func missingUnitsCarriesThroughAsNil() throws {
        let box = ScannedBox(nationalCode: "662025", serial: "SN-1", units: nil, expiry: nil)
        let preview = ScanMergePreview(decision: .create(units: nil), medicationID: nil, medicationName: nil)

        let model = scanConfirmation(suggestion: suggestion(), box: box, preview: preview)

        #expect(model.units == nil)
    }

    @Test("An addStock preview missing the medication identity degrades to create, defensively")
    func addStockMissingIdentityDegradesToCreate() throws {
        // Shouldn't happen in practice (the actor always names the match it found), but
        // the model must still be safe to build rather than force-unwrap.
        let box = ScannedBox(nationalCode: "662025", serial: "SN-1", units: 20, expiry: nil)
        let preview = ScanMergePreview(decision: .addStock(units: 20), medicationID: nil, medicationName: nil)

        let model = scanConfirmation(suggestion: suggestion(), box: box, preview: preview)

        #expect(model.action == .create)
    }
}
