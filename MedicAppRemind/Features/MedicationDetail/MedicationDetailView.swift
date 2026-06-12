//
//  MedicationDetailView.swift
//  MedicAppRemind
//
//  F3.S3 — Deep-link destination. A deliberately minimal placeholder: it proves a
//  notification opens the *correct* medication. The full detail layout is F6.S2,
//  which builds it from the design mockup — do not flesh this out here.
//
//  F4.S2 — Adds the accessible "add to calendar" toggle and the refill-reminder
//  button. These are the real controls; F6.S2 reuses CalendarSyncService when it
//  rebuilds this screen from the mockup.
//

import SwiftUI
import SwiftData

/// Resolves a medication by id and shows enough to confirm the deep-link landed
/// on the right one, plus the calendar-sync controls. Replaced by the real detail
/// screen in F6.S2.
struct MedicationDetailView: View {
    @Query private var medications: [MedicationModel]

    init(medicationID: UUID) {
        _medications = Query(filter: #Predicate { $0.id == medicationID })
    }

    var body: some View {
        if let medication = medications.first {
            Form {
                Section("Detalle completo en F6.S2") {
                    Text(medication.name)
                        .font(.title2)
                }
                MedicationCalendarSection(medication: medication)
            }
            .navigationTitle(medication.name)
        } else {
            ContentUnavailableView(
                "Medicamento no encontrado",
                systemImage: "pills",
                description: Text("Puede que se haya eliminado.")
            )
        }
    }
}
