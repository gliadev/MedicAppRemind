//
//  CIMAServiceTests.swift
//  MedicAppRemindTests
//
//  FX.S2 — CIMAService against a stubbed URLSession (StubURLProtocol); no real
//  network traffic. Fixtures are real CIMA payloads captured 2026-07-09 (see
//  CIMAFixtures.swift, docs/specs/10-FaseFX-Scanner.md §FX.S2).
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("CIMAService")
struct CIMAServiceTests {

    /// Fresh stubbed `URLSession` + fresh `CIMAService` per test. The actor-backed
    /// store is reset first so no test can see another test's stubs or hit counts.
    private func makeSUT() async -> CIMAService {
        await URLProtocolStubStore.shared.reset()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        return CIMAService(session: session)
    }

    // MARK: - medicamento(for:)

    @Test("medicamento?nregistro=70310 decodes the name and the preferred active-ingredient dose")
    func medicamentoDecodesNameAndPrincipioActivo() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/medicamento?nregistro=70310",
            data: Data(CIMAFixtures.medicamento70310.utf8)
        )

        let medicamento = try await sut.medicamento(for: .nregistro("70310"))

        #expect(medicamento.nombre == "PARACETAMOL CINFA 1 g COMPRIMIDOS EFG")
        let principioActivo = try #require(medicamento.principiosActivos?.first)
        #expect(principioActivo.nombre == "PARACETAMOL")
        #expect(principioActivo.cantidad == "1000")
        #expect(principioActivo.unidad == "mg")
    }

    @Test("medicamento?cn= builds the CN query variant of the same endpoint")
    func medicamentoByCNBuildsCNQuery() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/medicamento?cn=662025",
            data: Data(CIMAFixtures.medicamento70310.utf8)
        )

        let medicamento = try await sut.medicamento(for: .cn("662025"))

        #expect(medicamento.nregistro == "70310")
    }

    // MARK: - presentacion(cn:)

    @Test("presentacion/662025 yields a name PackageUnitsParser resolves to 20 units")
    func presentacionResolvesPackageUnits() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/presentacion/662025",
            data: Data(CIMAFixtures.presentacion662025.utf8)
        )

        let presentacion = try await sut.presentacion(cn: "662025")

        #expect(presentacion.cn == "662025")
        #expect(PackageUnitsParser.packageUnits(fromPresentationName: presentacion.nombre) == 20)
    }

    // MARK: - presentaciones(nregistro:) — QR route, multiple packagings

    @Test("presentaciones?nregistro=70310 decodes both packagings from the paginated wrapper")
    func presentacionesDecodesPaginatedWrapper() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/presentaciones?nregistro=70310",
            data: Data(CIMAFixtures.presentaciones70310.utf8)
        )

        let presentaciones = try await sut.presentaciones(nregistro: "70310")

        #expect(presentaciones.map(\.cn) == ["662025", "662026"])
        #expect(PackageUnitsParser.packageUnits(fromPresentationName: presentaciones[1].nombre) == 40)
    }

    // MARK: - Errors

    @Test("A CN with no match (204, empty body) surfaces as .notFound, not a decoding crash")
    func unmatchedCNSurfacesNotFound() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/medicamento?cn=000000",
            data: Data(),
            statusCode: 204
        )

        await #expect(throws: LookupError.notFound) {
            try await sut.medicamento(for: .cn("000000"))
        }
    }

    @Test("Corrupted JSON surfaces as .decoding")
    func corruptedJSONSurfacesDecodingError() async throws {
        let sut = await makeSUT()
        await URLProtocolStubStore.shared.stub(
            url: "https://cima.aemps.es/cima/rest/medicamento?cn=681957",
            data: Data("{ not valid json".utf8)
        )

        await #expect(throws: LookupError.decoding) {
            try await sut.medicamento(for: .cn("681957"))
        }
    }

    // MARK: - Cache

    @Test("A second lookup of the same identifier hits the in-memory cache, not the network")
    func secondLookupSameIdentifierUsesCache() async throws {
        let sut = await makeSUT()
        let url = "https://cima.aemps.es/cima/rest/medicamento?nregistro=70310"
        await URLProtocolStubStore.shared.stub(url: url, data: Data(CIMAFixtures.medicamento70310.utf8))

        _ = try await sut.medicamento(for: .nregistro("70310"))
        _ = try await sut.medicamento(for: .nregistro("70310"))

        #expect(await URLProtocolStubStore.shared.requestCount(for: url) == 1)
    }

    @Test("Different identifiers are cached independently — no cross-contamination")
    func differentIdentifiersCacheIndependently() async throws {
        let sut = await makeSUT()
        let nregUrl = "https://cima.aemps.es/cima/rest/medicamento?nregistro=70310"
        let cnUrl = "https://cima.aemps.es/cima/rest/medicamento?cn=662025"
        await URLProtocolStubStore.shared.stub(url: nregUrl, data: Data(CIMAFixtures.medicamento70310.utf8))
        await URLProtocolStubStore.shared.stub(url: cnUrl, data: Data(CIMAFixtures.medicamento70310.utf8))

        _ = try await sut.medicamento(for: .nregistro("70310"))
        _ = try await sut.medicamento(for: .cn("662025"))

        #expect(await URLProtocolStubStore.shared.requestCount(for: nregUrl) == 1)
        #expect(await URLProtocolStubStore.shared.requestCount(for: cnUrl) == 1)
    }
}

// MARK: - Editor-suggestion mapping (pure — no network involved)

@Suite("MedicationLookupSuggestion")
struct MedicationLookupSuggestionTests {

    private func decodeMedicamento(_ json: String) throws -> CIMAMedicamento {
        try JSONDecoder().decode(CIMAMedicamento.self, from: Data(json.utf8))
    }

    @Test("A single active ingredient maps to a structured 'cantidad unidad' dose suggestion")
    func singlePrincipioActivoMapsToStructuredDose() throws {
        let medicamento = try decodeMedicamento(CIMAFixtures.medicamento70310)

        let suggestion = MedicationLookupSuggestion(cimaMedicamento: medicamento)

        #expect(suggestion.nombre == "PARACETAMOL CINFA 1 g COMPRIMIDOS EFG")
        #expect(suggestion.dosis == "1000 mg")
    }

    @Test("Multiple active ingredients disable dose autofill — the user decides, never silent")
    func multiPrincipioActivoDisablesDoseAutofill() throws {
        let medicamento = try decodeMedicamento(CIMAFixtures.medicamentoMultiPA67892)

        let suggestion = MedicationLookupSuggestion(cimaMedicamento: medicamento)

        #expect(suggestion.nombre == "AMOXICILINA/ACIDO CLAVULANICO CINFA 875 mg/125 mg COMPRIMIDOS RECUBIERTOS CON PELICULA EFG")
        #expect(suggestion.dosis == nil)
    }
}

// MARK: - Packaging photo (FX.S5 — visual confirmation in the scan sheet)

@Suite("CIMAMedicamento.photoURL")
struct CIMAMedicamentoPhotoURLTests {

    private func decodeMedicamento(_ json: String) throws -> CIMAMedicamento {
        try JSONDecoder().decode(CIMAMedicamento.self, from: Data(json.utf8))
    }

    @Test("Prefers the box photo (formafarmac) over the materials photo")
    func prefersFormafarmacPhoto() throws {
        let medicamento = try decodeMedicamento(CIMAFixtures.medicamento70310)

        #expect(medicamento.photoURL == URL(string: "https://cima.aemps.es/cima/fotos/thumbnails/formafarmac/70310/70310_formafarmac.jpg"))
    }

    @Test("No fotos array yields no photo, never a crash")
    func noFotosYieldsNil() throws {
        let medicamento = try JSONDecoder().decode(CIMAMedicamento.self, from: Data(#"{"nregistro":"1","nombre":"X"}"#.utf8))

        #expect(medicamento.photoURL == nil)
    }

    @Test("A non-CIMA photo host is refused, defense in depth even though the JSON is CIMA's own")
    func nonCIMAHostRefused() throws {
        let medicamento = try JSONDecoder().decode(
            CIMAMedicamento.self,
            from: Data(#"{"nregistro":"1","nombre":"X","fotos":[{"tipo":"formafarmac","url":"https://evil.example/x.jpg"}]}"#.utf8)
        )

        #expect(medicamento.photoURL == nil)
    }
}
