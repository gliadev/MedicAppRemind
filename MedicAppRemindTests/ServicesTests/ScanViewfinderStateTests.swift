//
//  ScanViewfinderStateTests.swift
//  MedicAppRemindTests
//
//  FX.S3 — The viewfinder state machine, tested as a pure reducer: every event
//  from every meaningful state maps to a hand-computed next state. Guarantees no
//  dead ends (each failure lands on a recoverable state).
//

import Testing
@testable import MedicAppRemind

@Suite("Scan viewfinder state")
struct ScanViewfinderStateTests {

    private let suggestion = MedicationLookupSuggestion(
        cimaMedicamento: CIMAMedicamento(
            nregistro: "70310",
            nombre: "Paracetamol Cinfa 1 g",
            dosis: "1 g",
            labtitular: nil,
            receta: nil,
            principiosActivos: [.init(nombre: "paracetamol", cantidad: "1", unidad: "g")]
        )
    )

    @Test("A detected code moves scanning → looking")
    func detectingACodeStartsLookup() {
        let next = ScanViewfinderState.scanning.reduced(on: .codeDetected(.cn("658493")))
        #expect(next == .looking(.cn("658493")))
    }

    @Test("A late repeat can't overwrite a result already on screen")
    func lateCodeIgnoredOnceFound() {
        let found = ScanViewfinderState.found(suggestion)
        #expect(found.reduced(on: .codeDetected(.cn("999999"))) == found)
    }

    @Test("A successful lookup shows the suggestion")
    func successShowsSuggestion() {
        let next = ScanViewfinderState.looking(.cn("658493")).reduced(on: .lookupSucceeded(suggestion))
        #expect(next == .found(suggestion))
    }

    @Test("A network failure offers a retry for the same code")
    func networkFailureBecomesOffline() {
        let next = ScanViewfinderState.looking(.cn("658493")).reduced(on: .lookupFailed(.network))
        #expect(next == .offline(.cn("658493")))
    }

    @Test("A not-found result routes to manual entry")
    func notFoundBecomesManual() {
        let next = ScanViewfinderState.looking(.cn("000000")).reduced(on: .lookupFailed(.notFound))
        #expect(next == .notFound)
    }

    @Test("A decoding failure also routes to manual entry")
    func decodingFailureBecomesManual() {
        let next = ScanViewfinderState.looking(.cn("000000")).reduced(on: .lookupFailed(.decoding))
        #expect(next == .notFound)
    }

    @Test("Denied camera permission overrides any state")
    func permissionDeniedFromAnyState() {
        #expect(ScanViewfinderState.scanning.reduced(on: .cameraPermissionDenied) == .cameraDenied)
        #expect(ScanViewfinderState.found(suggestion).reduced(on: .cameraPermissionDenied) == .cameraDenied)
    }

    @Test("Retry from offline re-queries the same code")
    func retryResumesLookup() {
        let next = ScanViewfinderState.offline(.cn("658493")).reduced(on: .retry)
        #expect(next == .looking(.cn("658493")))
    }

    @Test("Reset returns to scanning")
    func resetReturnsToScanning() {
        #expect(ScanViewfinderState.found(suggestion).reduced(on: .reset) == .scanning)
    }
}
