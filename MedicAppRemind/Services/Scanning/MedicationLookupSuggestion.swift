//
//  MedicationLookupSuggestion.swift
//  MedicAppRemind
//
//  FX.S2 — Maps a CIMA lookup to what the confirmation sheet (FX.S5) offers to
//  autofill. Dose autofill only fires when there's exactly one active
//  ingredient: with more than one, the fields the editor would need to split
//  are ambiguous, so the user decides instead — autofill is never silent.
//

struct MedicationLookupSuggestion: Sendable, Equatable {
    let nombre: String
    let dosis: String?

    init(cimaMedicamento medicamento: CIMAMedicamento) {
        nombre = medicamento.nombre
        switch medicamento.principiosActivos?.count ?? 0 {
        case 1:
            let principioActivo = medicamento.principiosActivos?[0]
            if let cantidad = principioActivo?.cantidad, let unidad = principioActivo?.unidad {
                dosis = "\(cantidad) \(unidad)"
            } else {
                dosis = medicamento.dosis
            }
        case 0:
            dosis = medicamento.dosis
        default:
            dosis = nil
        }
    }
}
