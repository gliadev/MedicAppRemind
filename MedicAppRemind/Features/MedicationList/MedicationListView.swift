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
    @Environment(\.cloudSyncMonitor) private var cloudSyncMonitor
    @Query(sort: \MedicationModel.name) private var medications: [MedicationModel]

    @State private var showingAddEditor = false

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            List(medications) { medication in
                NavigationLink(value: medication.id) {
                    MedicationRow(model: medication)
                }
            }
            .navigationTitle("Medicamentos")
            .navigationDestination(for: UUID.self) { medicationID in
                MedicationDetailView(medicationID: medicationID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Añadir medicamento", systemImage: "plus") {
                        showingAddEditor = true
                    }
                }
                if cloudSyncMonitor?.isSyncing == true {
                    ToolbarItem(placement: .topBarLeading) {
                        SyncStatusLabel()
                    }
                }
            }
            .overlay {
                if medications.isEmpty {
                    if cloudSyncMonitor?.isSyncing == true {
                        CloudSyncingView()
                    } else {
                        ContentUnavailableView(
                            "Sin medicamentos",
                            systemImage: "pills",
                            description: Text("Añade tu primer medicamento para empezar.")
                        )
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddEditor) {
            MedicationEditorView()
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
