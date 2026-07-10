//
//  GS1ParserTests.swift
//  MedicAppRemindTests
//
//  FX.S1 — GS1 DataMatrix parsing + medicine identifiers. The four fixtures are
//  real payloads decoded from physical Spanish boxes (research §5.5), with the
//  FNC1 group separator (\u{1D}) explicit — without it, variable-length AIs are
//  undelimitable. Every test fixes an input and asserts a hand-computed output.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("GS1Parser")
struct GS1ParserTests {

    /// Fixed UTC calendar so expiry-date tests never depend on the machine's zone.
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    // MARK: - Real-world fixtures (research §5.5, decoded 2026-06-11)

    @Test("Lorazepam box (AI order 01·17·10·21) resolves every field via NTIN")
    func lorazepamFixtureParsesAllFields() {
        let code = GS1Parser.parse("01084700065849341727083110BZ4137\u{1D}21K4G1S4G5A")
        #expect(code.gtin == "08470006584934")
        #expect(code.nationalCode == "658493")
        #expect(code.expiry == "270831")
        #expect(code.lot == "BZ4137")
        #expect(code.serial == "K4G1S4G5A")
    }

    @Test("Enantyum box (AI order 01·10·17·21, numeric lot) resolves via NTIN")
    func enantyumFixtureParsesNumericLot() {
        let code = GS1Parser.parse("01084700068195791025241\u{1D}1727113021K2KB4RNWCF")
        #expect(code.gtin == "08470006819579")
        #expect(code.nationalCode == "681957")
        #expect(code.expiry == "271130")
        #expect(code.lot == "25241")
        #expect(code.serial == "K2KB4RNWCF")
    }

    @Test("White box (AI order 01·17·10·21) resolves via NTIN")
    func whiteBoxFixtureParsesAllFields() {
        let code = GS1Parser.parse("010847000662026717300531" + "10PCB25189\u{1D}21NEE35LYXT")
        #expect(code.gtin == "08470006620267")
        #expect(code.nationalCode == "662026")
        #expect(code.expiry == "300531")
        #expect(code.lot == "PCB25189")
        #expect(code.serial == "NEE35LYXT")
    }

    @Test("Black box (AI order 01·21·10·17·712): CN comes from AI 712, check digit dropped")
    func blackBoxFixtureResolvesCNFromAI712() {
        let code = GS1Parser.parse("010843523234461521TTM5RER78RHW\u{1D}10AA521\u{1D}172810317126639825")
        #expect(code.gtin == "08435232344615")
        #expect(code.nationalCode == "663982")
        #expect(code.expiry == "281031")
        #expect(code.lot == "AA521")
        #expect(code.serial == "TTM5RER78RHW")
    }

    // MARK: - Parser edge cases

    @Test("The ]d2 symbology identifier prefix is ignored")
    func symbologyPrefixIsIgnored() {
        let code = GS1Parser.parse("]d201084700065849341727083110BZ4137\u{1D}21K4G1S4G5A")
        #expect(code.nationalCode == "658493")
        #expect(code.expiry == "270831")
    }

    @Test("An unknown AI stops parsing safely, keeping the fields already read")
    func unknownAIYieldsPartialResult() {
        let code = GS1Parser.parse("010847000658493499XYZ")
        #expect(code.gtin == "08470006584934")
        #expect(code.nationalCode == "658493")
        #expect(code.expiry == nil)
        #expect(code.lot == nil)
        #expect(code.serial == nil)
    }

    @Test("Foreign GTIN without AI 712 yields no national code")
    func foreignGTINWithout712HasNoNationalCode() {
        let code = GS1Parser.parse("01084352323446151725063010LOT1\u{1D}21SER1")
        #expect(code.gtin == "08435232344615")
        #expect(code.nationalCode == nil)
    }

    @Test("An empty payload yields an all-nil result")
    func emptyPayloadIsAllNil() {
        #expect(GS1Parser.parse("") == ScannedMedicineCode())
    }

    // MARK: - expiryDate(fromYYMMDD:calendar:)

    @Test("Explicit day: 280331 is 2028-03-31")
    func expiryWithExplicitDay() throws {
        let expected = try #require(utcCalendar.date(from: DateComponents(year: 2028, month: 3, day: 31)))
        #expect(GS1Parser.expiryDate(fromYYMMDD: "280331", calendar: utcCalendar) == expected)
    }

    @Test("GS1 rule DD=00: 271100 is the last day of November 2027")
    func expiryDayZeroIsEndOfMonth() throws {
        let expected = try #require(utcCalendar.date(from: DateComponents(year: 2027, month: 11, day: 30)))
        #expect(GS1Parser.expiryDate(fromYYMMDD: "271100", calendar: utcCalendar) == expected)
    }

    @Test("GS1 rule DD=00 in a leap February: 280200 is 2028-02-29")
    func expiryDayZeroInLeapFebruary() throws {
        let expected = try #require(utcCalendar.date(from: DateComponents(year: 2028, month: 2, day: 29)))
        #expect(GS1Parser.expiryDate(fromYYMMDD: "280200", calendar: utcCalendar) == expected)
    }

    @Test("Invalid expiry values are rejected", arguments: ["2803", "28AB31", "281331", "280001", "280230"])
    func invalidExpiryIsNil(value: String) {
        #expect(GS1Parser.expiryDate(fromYYMMDD: value, calendar: Calendar(identifier: .gregorian)) == nil)
    }

    // MARK: - nationalCode(fromEAN13:)

    @Test("Spanish EAN-13 (847000 prefix) yields the embedded CN")
    func spanishEAN13YieldsCN() {
        #expect(GS1Parser.nationalCode(fromEAN13: "8470006819579") == "681957")
    }

    @Test("Non-Spanish or malformed EAN-13 yields nil", arguments: ["5012345678900", "847000681957", "84700068195790", "8470O0681957X"])
    func nonSpanishEAN13IsNil(code: String) {
        #expect(GS1Parser.nationalCode(fromEAN13: code) == nil)
    }

    // MARK: - MedicineIdentifier from leaflet-QR URL

    @Test("A CIMA leaflet URL yields its nregistro")
    func cimaLeafletURLYieldsNRegistro() {
        let identifier = MedicineIdentifier(cimaURL: "https://cima.aemps.es/cima/dochtml/p/68477/P_68477.html")
        #expect(identifier == .nregistro("68477"))
    }

    @Test("A QR whose host is not cima.aemps.es is rejected", arguments: [
        "https://evil.example/cima/dochtml/p/68477/P_68477.html",
        "https://cima.aemps.es.evil.example/cima/dochtml/p/68477/P_68477.html",
    ])
    func foreignHostIsRejected(url: String) {
        #expect(MedicineIdentifier(cimaURL: url) == nil)
    }

    @Test("A CIMA URL without a numeric component after /p/ is rejected", arguments: [
        "https://cima.aemps.es/cima/rest/medicamento",
        "https://cima.aemps.es/cima/dochtml/p/P_68477.html",
    ])
    func cimaURLWithoutNRegistroIsRejected(url: String) {
        #expect(MedicineIdentifier(cimaURL: url) == nil)
    }

    // MARK: - packageUnits(fromPresentationName:)

    @Test("Presentation names yield their unit count, ignoring the dose number", arguments: [
        ("ENANTYUM 25 mg COMPRIMIDOS RECUBIERTOS CON PELICULA, 20 comprimidos", 20),
        ("VITAMINA D3 KERN PHARMA 25.000 UI, 10 cápsulas blandas", 10),
        ("PARACETAMOL CINFA 650 mg COMPRIMIDOS EFG, 40 comprimidos", 40),
        ("FLUIMUCIL FORTE 600 mg GRANULADO PARA SOLUCION ORAL, 30 sobres", 30),
        ("METILPREDNISOLONA 40 mg POLVO PARA SOLUCION INYECTABLE, 1 vial", 1),
    ])
    func presentationNameYieldsUnits(name: String, units: Int) {
        #expect(PackageUnitsParser.packageUnits(fromPresentationName: name) == units)
    }

    @Test("A presentation name without a unit count yields nil", arguments: [
        "IBUPROFENO 600 mg COMPRIMIDOS RECUBIERTOS",
        "DALSY 20 mg/ml SUSPENSION ORAL, 200 ml",
    ])
    func presentationNameWithoutUnitsIsNil(name: String) {
        #expect(PackageUnitsParser.packageUnits(fromPresentationName: name) == nil)
    }
}
