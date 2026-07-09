//
//  ScanRoutingTests.swift
//  MedicAppRemindTests
//
//  FX.S3 — The pure routing extracted from the camera bridge: (value, symbology)
//  → MedicineIdentifier, the debounce that collapses ~30 fps repeats, and the
//  AVFoundation type mapping. DataMatrix/EAN payloads are real (research §5.5).
//

import Testing
import AVFoundation
@testable import MedicAppRemind

@Suite("Scan routing")
struct ScanRoutingTests {

    // MARK: - Symbology → identifier

    @Test("DataMatrix routes to the CN parsed from its GS1 payload")
    func dataMatrixRoutesToNationalCode() {
        let identifier = ScanRouter.identifier(
            for: "01084700065849341727083110BZ4137\u{1D}21K4G1S4G5A",
            symbology: .dataMatrix
        )
        #expect(identifier == .cn("658493"))
    }

    @Test("A Spanish EAN-13 (847000…) routes to its CN")
    func ean13RoutesToNationalCode() {
        #expect(ScanRouter.identifier(for: "8470006819579", symbology: .ean13) == .cn("681957"))
    }

    @Test("A leaflet QR on cima.aemps.es routes to its nregistro")
    func cimaQRRoutesToNregistro() {
        let identifier = ScanRouter.identifier(
            for: "https://cima.aemps.es/cima/dochtml/p/68477/P_68477.html",
            symbology: .qr
        )
        #expect(identifier == .nregistro("68477"))
    }

    @Test("A foreign EAN-13 carries no Spanish CN")
    func foreignEAN13IsIgnored() {
        #expect(ScanRouter.identifier(for: "4006381333931", symbology: .ean13) == nil)
    }

    @Test("A QR on any other host is refused (anti-phishing)")
    func nonCimaQRIsIgnored() {
        #expect(ScanRouter.identifier(for: "https://evil.example/p/123", symbology: .qr) == nil)
    }

    // MARK: - Debounce

    @Test("The same value routes once until a different one arrives")
    func debouncerCollapsesRepeats() {
        var debouncer = ScanDebouncer()
        #expect(debouncer.shouldHandle("ABC") == true)
        #expect(debouncer.shouldHandle("ABC") == false)
        #expect(debouncer.shouldHandle("DEF") == true)
        #expect(debouncer.shouldHandle("DEF") == false)
    }

    @Test("Resetting lets the same box be rescanned after a failure")
    func debouncerResetAllowsRescan() {
        var debouncer = ScanDebouncer()
        #expect(debouncer.shouldHandle("ABC") == true)
        debouncer.reset()
        #expect(debouncer.shouldHandle("ABC") == true)
    }

    // MARK: - AVFoundation type mapping

    @Test("Only the three scanned metadata types map; anything else is ignored")
    func metadataTypeMapping() {
        #expect(ScanSymbology(metadataType: .dataMatrix) == .dataMatrix)
        #expect(ScanSymbology(metadataType: .qr) == .qr)
        #expect(ScanSymbology(metadataType: .ean13) == .ean13)
        #expect(ScanSymbology(metadataType: .face) == nil)
    }
}
