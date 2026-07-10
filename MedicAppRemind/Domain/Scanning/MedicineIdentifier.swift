//
//  MedicineIdentifier.swift
//  MedicAppRemind
//
//  FX.S1 — The identifier a scanned Spanish medicine box resolves to. CIMA
//  accepts both: the CN identifies a *presentation* (a concrete package),
//  the nregistro the *medicine* itself.
//

import Foundation

enum MedicineIdentifier: Equatable, Hashable {
    /// Código Nacional (6 digits), from the DataMatrix or a Spanish EAN-13.
    case cn(String)
    /// AEMPS registration number, from the leaflet QR.
    case nregistro(String)
}

extension MedicineIdentifier {
    /// Extracts the nregistro from a scanned leaflet-QR URL, e.g.
    /// `https://cima.aemps.es/cima/dochtml/p/68477/P_68477.html`.
    ///
    /// The URL itself is never opened. Anti QR-phishing: only accepted when the
    /// host is exactly `cima.aemps.es` and the component after "p" is numeric.
    init?(cimaURL raw: String) {
        guard let url = URL(string: raw), url.host() == "cima.aemps.es" else { return nil }
        let parts = url.pathComponents
        guard let index = parts.firstIndex(of: "p"), parts.indices.contains(index + 1) else { return nil }
        let candidate = parts[index + 1]
        guard !candidate.isEmpty, candidate.allSatisfy(\.isNumber) else { return nil }
        self = .nregistro(candidate)
    }
}
