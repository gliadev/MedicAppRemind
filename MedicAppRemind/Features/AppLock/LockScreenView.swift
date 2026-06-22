//
//  LockScreenView.swift
//  MedicAppRemind
//
//  Security finding #5 — lock screen shown when the app returns from background
//  with biometric lock enabled. Triggers the Face ID / Touch ID prompt automatically
//  on appear; the user can also retry manually.
//

import SwiftUI

struct LockScreenView: View {
    let onUnlock: () async -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text("MediRemind bloqueado")
                .font(.title2.bold())

            Text("Desbloquea la app para acceder a tu medicación.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Button("Desbloquear", systemImage: "faceid") {
                Task { await onUnlock() }
            }
            .buttonStyle(.borderedProminent)
            .accessibilityHint("Solicita verificación con Face ID o Touch ID")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        // Auto-prompt Face ID when the lock screen appears.
        .task { await onUnlock() }
    }
}
