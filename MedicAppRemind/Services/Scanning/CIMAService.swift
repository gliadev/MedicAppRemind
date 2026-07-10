//
//  CIMAService.swift
//  MedicAppRemind
//
//  FX.S2 — MedicationLookupService backed by the public CIMA REST API (AEMPS),
//  no auth. An actor because it also owns the in-memory lookup cache: CIMA's
//  rate limits aren't documented (research §3), so a rescan of the same box
//  should never re-hit the network.
//

import Foundation

actor CIMAService: MedicationLookupService {
    private let session: URLSession
    private var medicamentoCache: [MedicineIdentifier: CIMAMedicamento] = [:]

    init(session: URLSession = .shared) {
        self.session = session
    }

    func medicamento(for id: MedicineIdentifier) async throws -> CIMAMedicamento {
        if let cached = medicamentoCache[id] {
            return cached
        }
        let url = try medicamentoURL(for: id)
        let medicamento: CIMAMedicamento = try await fetch(from: url)
        medicamentoCache[id] = medicamento
        return medicamento
    }

    func presentacion(cn: String) async throws -> CIMAPresentacion {
        guard let url = URL(string: "https://cima.aemps.es/cima/rest/presentacion/\(cn)") else {
            throw LookupError.network
        }
        return try await fetch(from: url)
    }

    func presentaciones(nregistro: String) async throws -> [CIMAPresentacion] {
        var components = URLComponents(string: "https://cima.aemps.es/cima/rest/presentaciones")
        components?.queryItems = [URLQueryItem(name: "nregistro", value: nregistro)]
        guard let url = components?.url else { throw LookupError.network }
        let page: CIMAPresentacionesPage = try await fetch(from: url)
        return page.resultados
    }

    private func medicamentoURL(for id: MedicineIdentifier) throws -> URL {
        var components = URLComponents(string: "https://cima.aemps.es/cima/rest/medicamento")
        switch id {
        case .cn(let cn):
            components?.queryItems = [URLQueryItem(name: "cn", value: cn)]
        case .nregistro(let nregistro):
            components?.queryItems = [URLQueryItem(name: "nregistro", value: nregistro)]
        }
        guard let url = components?.url else { throw LookupError.network }
        return url
    }

    private func fetch<T: Decodable>(from url: URL) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw LookupError.network
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200, !data.isEmpty else {
            throw LookupError.notFound
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LookupError.decoding
        }
    }
}
