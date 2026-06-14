//
//  SyncStatusLabel.swift
//  MedicAppRemind
//
//  F7.S2 — Small, non-blocking "Sincronizando…" indicator for a toolbar, shown
//  while CloudKit is importing/exporting. Combines a spinner with text so the
//  state is never conveyed by motion alone; VoiceOver reads it as one phrase.
//

import SwiftUI

/// A compact sync-in-progress indicator (spinner + label) for use in a toolbar.
struct SyncStatusLabel: View {
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .controlSize(.small)
            Text("Sincronizando…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sincronizando con iCloud")
    }
}

#Preview {
    SyncStatusLabel()
}
