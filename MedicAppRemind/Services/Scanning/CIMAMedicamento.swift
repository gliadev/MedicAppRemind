//
//  CIMAMedicamento.swift
//  MedicAppRemind
//
//  FX.S2 — CIMA `medicamento` DTO. Extra JSON fields CIMA returns (docs, fotos,
//  atcs, presentaciones…) are intentionally left unmodelled; `Decodable` ignores
//  keys with no matching property.
//

import Foundation

struct CIMAMedicamento: Decodable, Sendable {
    let nregistro: String
    let nombre: String
    let dosis: String?
    let labtitular: String?
    let receta: Bool?
    let principiosActivos: [PrincipioActivo]?

    struct PrincipioActivo: Decodable, Sendable {
        let nombre: String
        let cantidad: String?
        let unidad: String?
    }
}
