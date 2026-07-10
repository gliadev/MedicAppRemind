//
//  CIMAMedicamento.swift
//  MedicAppRemind
//
//  FX.S2 — CIMA `medicamento` DTO. Extra JSON fields CIMA returns (docs,
//  atcs, presentaciones…) are intentionally left unmodelled; `Decodable` ignores
//  keys with no matching property. `fotos` was added in FX.S5 for the scan
//  confirmation sheet's visual check.
//

import Foundation

struct CIMAMedicamento: Decodable, Sendable {
    let nregistro: String
    let nombre: String
    let dosis: String?
    let labtitular: String?
    let receta: Bool?
    let principiosActivos: [PrincipioActivo]?
    let fotos: [Foto]?

    init(
        nregistro: String,
        nombre: String,
        dosis: String?,
        labtitular: String?,
        receta: Bool?,
        principiosActivos: [PrincipioActivo]?,
        fotos: [Foto]? = nil
    ) {
        self.nregistro = nregistro
        self.nombre = nombre
        self.dosis = dosis
        self.labtitular = labtitular
        self.receta = receta
        self.principiosActivos = principiosActivos
        self.fotos = fotos
    }

    struct PrincipioActivo: Decodable, Sendable {
        let nombre: String
        let cantidad: String?
        let unidad: String?
    }

    struct Foto: Decodable, Sendable {
        let tipo: String
        let url: String
    }
}

extension CIMAMedicamento {
    /// The packaging photo CIMA has for this medicine, shown in the scan confirmation
    /// sheet (FX.S5) as a visual check — never opened as a link, only rendered as an
    /// image. Prefers the box photo ("formafarmac") over the materials photo, falling
    /// back to whichever comes first. Even though the URL comes from CIMA's own JSON
    /// response (not user input), it's still restricted to `https://cima.aemps.es`
    /// defense-in-depth, matching the QR anti-phishing check.
    var photoURL: URL? {
        let preferred = fotos?.first { $0.tipo == "formafarmac" } ?? fotos?.first
        guard let raw = preferred?.url,
              let url = URL(string: raw),
              url.scheme == "https",
              url.host() == "cima.aemps.es"
        else { return nil }
        return url
    }
}
