//
//  CIMAPresentacion.swift
//  MedicAppRemind
//
//  FX.S2 — CIMA `presentacion` DTO, plus the paginated wrapper `presentaciones`
//  returns (QR route: a medicine with more than one packaging).
//

import Foundation

struct CIMAPresentacion: Decodable, Equatable, Sendable {
    let cn: String
    let nombre: String
    let nregistro: String
}

struct CIMAPresentacionesPage: Decodable, Sendable {
    let totalFilas: Int
    let resultados: [CIMAPresentacion]
}
