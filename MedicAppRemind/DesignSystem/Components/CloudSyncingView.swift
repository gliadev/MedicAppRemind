//
//  CloudSyncingView.swift
//  MedicAppRemind
//
//  F7.S2 — Empty-state shown while CloudKit is still importing the user's data,
//  so a blank screen reads as "syncing" rather than "you have nothing". Text-based
//  and static: accessible to VoiceOver and safe under reduceMotion.
//

import SwiftUI

/// The "still importing from iCloud" empty state, shared by the medication list
/// and Today screens so both distinguish syncing from genuinely empty.
struct CloudSyncingView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Sincronizando…", systemImage: "arrow.triangle.2.circlepath")
        } description: {
            Text("Recuperando tus datos desde iCloud.")
        }
    }
}

#Preview {
    CloudSyncingView()
}
