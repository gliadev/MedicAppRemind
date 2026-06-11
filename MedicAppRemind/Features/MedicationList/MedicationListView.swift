//
//  MedicationListView.swift
//  MedicAppRemind
//
//  F2.S3 — Reactive medication list. `@Query` lives here, only in the view, as
//  the single source of truth; writes happen through `MedicationStoreActor` and
//  the list updates itself with no manual reload. No ViewModel over `@Query`.
//

import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \MedicationModel.name) private var medications: [MedicationModel]

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            List(medications) { medication in
                MedicationRow(model: medication)
            }
            .navigationTitle("Medicamentos")
            .navigationDestination(for: UUID.self) { medicationID in
                MedicationDetailView(medicationID: medicationID)
            }
            .overlay {
                if medications.isEmpty {
                    ContentUnavailableView(
                        "Sin medicamentos",
                        systemImage: "pills",
                        description: Text("Añade tu primer medicamento para empezar.")
                    )
                }
            }
        }
    }
}

#Preview {
    let controller = try? PersistenceController(inMemory: true)
    if let controller {
        MedicationListView()
            .modelContainer(controller.container)
            .environment(AppRouter())
    }
}
