//
//  DescribeFlowTests.swift
//  MedicAppRemindTests
//
//  F10.S3 — The describe flow against the parsing contract (FakeDraftParser,
//  never the real model): success yields the exact editor prefill, failure
//  preserves the person's text for the editor's notes, and the entry point
//  only exists when a parser is present AND available.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Describe flow (with FakeDraftParser)")
struct DescribeFlowTests {

    @Test("Fake OK → prefill con los campos exactos del draft")
    func successYieldsExactPrefill() async {
        let draft = MedicationDraft(
            name: "Ibuprofeno",
            doseLabel: "600 mg",
            pillsPerDose: 1,
            form: .pill,
            currentStock: 30,
            schedule: DraftSchedule(timesOfDay: nil, kind: .everyNHours(8)),
            sourceText: "Ibuprofeno 600, una cada 8 horas, me quedan 30"
        )
        let parser = FakeDraftParser(result: draft)

        let result = await describeFlowResult(text: draft.sourceText, parser: parser)
        #expect(result == .prefill(MedicationEditorPrefill(
            name: "Ibuprofeno",
            doseLabel: "600 mg",
            pillsPerDose: 1,
            form: .pill,
            currentStock: 30,
            schedule: DoseSchedulePrefill(times: [], frequency: .everyNHours(8))
        )))
    }

    @Test("Fake que lanza → fallo con el texto íntegro para las notas")
    func failurePreservesSourceText() async {
        let parser = FakeDraftParser(result: nil)
        let text = "recuérdame llamar al médico mañana"

        let result = await describeFlowResult(text: text, parser: parser)
        #expect(result == .failed(notesText: text))
    }

    @Test("Punto de entrada: solo con parser presente y disponible")
    func entryPointVisibility() {
        #expect(!showsDescribeEntry(nil))
        #expect(showsDescribeEntry(FakeDraftParser(isAvailable: true, result: nil)))
        #expect(!showsDescribeEntry(FakeDraftParser(isAvailable: false, result: nil)))
    }
}
