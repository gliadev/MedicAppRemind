//
//  ScannedMedicineCode.swift
//  MedicAppRemind
//
//  FX.S1 — The structured fields of a SEVeM DataMatrix, as parsed from its GS1
//  payload. Every field is optional: a foreign or partially readable code still
//  yields a safe, partial result the UI can act on.
//

struct ScannedMedicineCode: Equatable {
    /// AI 01 — product code (GTIN/NTIN, 14 digits).
    var gtin: String?
    /// CN resolved from either route: AI 712 (explicit) or the Spanish NTIN prefix.
    var nationalCode: String?
    /// AI 17 raw value (YYMMDD); convert with `GS1Parser.expiryDate(fromYYMMDD:calendar:)`.
    var expiry: String?
    /// AI 10 — batch number.
    var lot: String?
    /// AI 21 — serial number, unique per box.
    var serial: String?
}
