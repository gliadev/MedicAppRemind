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
    /// The shared on-disk container, resolved from `PersistenceController.shared`
    /// so the SwiftUI app and the App Intents runtime use the *same* container:
    /// a dose logged by an intent propagates to this UI's `@Query`. `?` because a
    /// failed store is handled in the UI rather than crashing (no force-unwrap).
    private let container: ModelContainer? = PersistenceController.shared?.container

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
