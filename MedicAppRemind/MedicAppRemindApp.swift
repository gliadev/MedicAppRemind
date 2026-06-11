//
//  MedicAppRemindApp.swift
//  MedicAppRemind
//
//  Created by Adolfo on 10/06/2026.
//

import SwiftUI
import SwiftData

@main
struct MedicAppRemindApp: App {
    /// The shared on-disk container. Built once at launch; the same container
    /// backs the UI's `@Query` and the `MedicationStoreActor` writes, so the
    /// list stays reactive. `try?` because a failed store is handled in the UI
    /// rather than crashing (no force-unwrap).
    private let container: ModelContainer? = try? PersistenceController().container

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView(container: container)
            } else {
                ContentUnavailableView(
                    "No se pudo abrir el almacén",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text("Reinicia la app. Si el problema continúa, contacta con soporte.")
                )
            }
        }
    }
}
