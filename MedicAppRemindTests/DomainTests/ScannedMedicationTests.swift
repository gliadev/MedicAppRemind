//
//  ScannedMedicationTests.swift
//  MedicAppRemindTests
//
//  v1.2 — The scanner only prefills the editor, so the parser must pull a sensible
//  name and dose from the messy text a box yields: separate lines, a combined line,
//  the dose appearing before the name, and odd spacing.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("ScannedMedication parser")
struct ScannedMedicationTests {

    @Test("Name and dose on separate lines")
    func nameAndDoseSeparateLines() {
        let scan = ScannedMedication(recognizedLines: ["Paracetamol", "500 mg", "20 comprimidos"])
        #expect(scan.name == "Paracetamol")
        #expect(scan.dose == "500 mg")
    }

    @Test("Name and dose on the same line: the dose is stripped from the name")
    func nameAndDoseSameLine() {
        let scan = ScannedMedication(recognizedLines: ["Ibuprofeno 600 mg"])
        #expect(scan.name == "Ibuprofeno")
        #expect(scan.dose == "600 mg")
    }

    @Test("A dose-only line is skipped for the name, even when it comes first")
    func doseLineBeforeNameIsSkipped() {
        let scan = ScannedMedication(recognizedLines: ["500 mg", "Paracetamol"])
        #expect(scan.name == "Paracetamol")
        #expect(scan.dose == "500 mg")
    }

    @Test("A missing space between number and unit is normalised")
    func missingSpaceIsNormalised() {
        let scan = ScannedMedication(recognizedLines: ["Amoxicilina 875mg"])
        #expect(scan.name == "Amoxicilina")
        #expect(scan.dose == "875 mg")
    }

    @Test("Decimal doses with a comma are kept")
    func decimalDoseWithComma() {
        let scan = ScannedMedication(recognizedLines: ["Gotas 0,5 ml"])
        #expect(scan.name == "Gotas")
        #expect(scan.dose == "0,5 ml")
    }

    @Test("No recognisable dose leaves only the name")
    func nameWithoutDose() {
        let scan = ScannedMedication(recognizedLines: ["Omeprazol"])
        #expect(scan.name == "Omeprazol")
        #expect(scan.dose == nil)
    }

    @Test("Empty input yields an empty suggestion")
    func emptyInput() {
        let scan = ScannedMedication(recognizedLines: [])
        #expect(scan.isEmpty)
    }
}
