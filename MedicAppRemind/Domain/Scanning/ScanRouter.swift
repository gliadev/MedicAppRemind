//
//  ScanRouter.swift
//  MedicAppRemind
//
//  FX.S3 — Turns a scanned code into the identifier CIMA can resolve, per
//  symbology. Pure and order-independent (the DataMatrix AI order varies between
//  manufacturers). A code carrying no extractable Spanish identifier yields
//  `nil`, so the UI falls back to manual entry — never a dead end, never a crash.
//

enum ScanRouter {
    /// Resolves the CIMA identifier for a scanned `value` of the given `symbology`.
    static func identifier(for value: String, symbology: ScanSymbology) -> MedicineIdentifier? {
        switch symbology {
        case .dataMatrix:
            guard let cn = GS1Parser.parse(value).nationalCode else { return nil }
            return .cn(cn)
        case .ean13:
            guard let cn = GS1Parser.nationalCode(fromEAN13: value) else { return nil }
            return .cn(cn)
        case .qr:
            // The URL is never opened; the initializer only accepts cima.aemps.es.
            return MedicineIdentifier(cimaURL: value)
        }
    }
}
