//
//  FakeDraftParserTests.swift
//  MedicAppRemindTests
//
//  F10.S2 — Contract of MedicationDraftParsing, verified against the fake the
//  UI tests will reuse (F10.S3). No test ever invokes the real model; device
//  behaviour is validated manually, like the FX scanner.
//

import Testing
import Foundation
@testable import MedicAppRemind

/// Test double for `MedicationDraftParsing`: returns a fixed draft or throws
/// the single public parser error, as configured.
struct FakeDraftParser: MedicationDraftParsing {
    var isAvailable: Bool = true
    var result: MedicationDraft?

    func parseDraft(from text: String) async throws -> MedicationDraft {
        guard let result else { throw DraftParserError.couldNotParse }
        return result
    }
}

@Suite("MedicationDraftParsing contract (via FakeDraftParser)")
struct FakeDraftParserTests {

    @Test("A configured fake returns its fixed draft")
    func fakeReturnsFixedDraft() async throws {
        let fixed = MedicationDraft(name: "Metformina", sourceText: "metformina 850")
        let parser = FakeDraftParser(result: fixed)

        let draft = try await parser.parseDraft(from: "metformina 850")
        #expect(draft == fixed)
        #expect(parser.isAvailable)
    }

    @Test("A failing fake throws the single public error case")
    func fakeThrowsCouldNotParse() async {
        let parser = FakeDraftParser(result: nil)
        await #expect(throws: DraftParserError.couldNotParse) {
            _ = try await parser.parseDraft(from: "recuérdame llamar al médico")
        }
    }

    @Test("The parser error localizes its description (never a bare case name)")
    func errorHasLocalizedDescription() {
        let error = DraftParserError.couldNotParse
        #expect(error.errorDescription?.isEmpty == false)
    }
}
