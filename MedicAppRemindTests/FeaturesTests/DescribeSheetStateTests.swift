//
//  DescribeSheetStateTests.swift
//  MedicAppRemindTests
//
//  F10.S3 — Pure state machine of the "Describir" sheet. Mirrors the
//  ScanViewfinderState discipline: every state can always get back to idle
//  (no dead ends), cancellation wins over in-flight results, and a blank
//  text never fires a request.
//

import Testing
@testable import MedicAppRemind

@Suite("DescribeSheetState reducer")
struct DescribeSheetStateTests {

    @Test("Interpretar con texto arranca la carga")
    func idleToLoading() {
        let next = DescribeSheetState.idle.reduced(on: .interpretTapped(text: "Ibuprofeno 600 cada 8 horas"))
        #expect(next == .loading)
    }

    @Test("Texto en blanco no dispara nada")
    func blankTextStaysIdle() {
        let next = DescribeSheetState.idle.reduced(on: .interpretTapped(text: "   \n "))
        #expect(next == .idle)
    }

    @Test("Éxito desde loading vuelve a idle (el sheet se cierra con el outcome)")
    func loadingToSuccess() {
        let next = DescribeSheetState.loading.reduced(on: .parseSucceeded)
        #expect(next == .idle)
    }

    @Test("Fallo desde loading muestra el estado de error")
    func loadingToFailed() {
        let next = DescribeSheetState.loading.reduced(on: .parseFailed)
        #expect(next == .failed)
    }

    @Test("Reintento tras fallo: Interpretar vuelve a cargar")
    func retryAfterFailure() {
        let next = DescribeSheetState.failed.reduced(on: .interpretTapped(text: "paracetamol 650"))
        #expect(next == .loading)
    }

    @Test("Cancelar desde loading vuelve a idle — siempre cancelable")
    func cancelFromLoading() {
        let next = DescribeSheetState.loading.reduced(on: .cancelled)
        #expect(next == .idle)
    }

    @Test("Un resultado tardío tras cancelar se ignora (no resucita el sheet)")
    func lateResultAfterCancelIgnored() {
        let cancelled = DescribeSheetState.loading.reduced(on: .cancelled)
        #expect(cancelled.reduced(on: .parseSucceeded) == .idle)
        #expect(cancelled.reduced(on: .parseFailed) == .idle)
    }

    @Test("Interpretar durante la carga no re-dispara")
    func noDoubleFireWhileLoading() {
        let next = DescribeSheetState.loading.reduced(on: .interpretTapped(text: "otra cosa"))
        #expect(next == .loading)
    }

    @Test("Cancelar desde fallo también sale a idle — sin callejones sin salida")
    func cancelFromFailure() {
        #expect(DescribeSheetState.failed.reduced(on: .cancelled) == .idle)
    }
}
