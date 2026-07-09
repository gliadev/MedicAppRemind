//
//  MedicationLookupService.swift
//  MedicAppRemind
//
//  FX.S2 — CIMA is the only implementation today; the protocol exists so the
//  scanner (FX.S3) and the confirmation sheet (FX.S5) depend on an abstraction,
//  not on URLSession directly.
//

/// CIMA accepts both identifiers directly, so every method mirrors a real endpoint:
/// `medicamento(for:)` → `medicamento?cn=|?nregistro=`; `presentacion(cn:)` →
/// `presentacion/{cn}`; `presentaciones(nregistro:)` → the QR route, where a
/// medicine can have more than one packaging.
protocol MedicationLookupService: Sendable {
    func medicamento(for id: MedicineIdentifier) async throws -> CIMAMedicamento
    func presentacion(cn: String) async throws -> CIMAPresentacion
    func presentaciones(nregistro: String) async throws -> [CIMAPresentacion]
}
