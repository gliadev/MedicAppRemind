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
    @Environment(AppLockMonitor.self) private var lockMonitor
    @Query(sort: \MedicationModel.name) private var medications: [MedicationModel]

    @State private var showingAddEditor = false
    @State private var lockError: String?
    @State private var showLockError = false

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
                ToolbarItem(placement: .topBarTrailing) {
                    Button(
                        lockMonitor.isEnabled ? "Desactivar bloqueo" : "Activar bloqueo",
                        systemImage: lockMonitor.isEnabled ? "lock.fill" : "lock.open"
                    ) {
                        Task { await toggleLock() }
                    }
                    .accessibilityHint(lockMonitor.isEnabled
                        ? "Desactiva el bloqueo biométrico de la app"
                        : "Activa Face ID o Touch ID para proteger tu medicación"
                    )
                    .accessibilityInputLabels(["Bloqueo"])
                }
                if cloudSyncMonitor?.isSyncing == true {
                    ToolbarItem(placement: .topBarLeading) {
                        SyncStatusLabel()
                    }
                }
            }
            .alert("Bloqueo biométrico", isPresented: $showLockError) {
                Button("OK") {}
            } message: {
                Text(lockError ?? "")
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

    private func toggleLock() async {
        if lockMonitor.isEnabled {
            await lockMonitor.disable()
        } else {
            do {
                try await lockMonitor.enable()
            } catch {
                lockError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                showLockError = true
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
