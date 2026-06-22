//
//  AppLockMonitor.swift
//  MedicAppRemind
//
//  Security finding #5 — observable lock state for the app-lock feature.
//  Owned by RootView; shared into the environment so MedicationListView
//  can expose the enable/disable toggle.
//

import Foundation

@MainActor
@Observable
final class AppLockMonitor {
    private(set) var isLocked = false
    private(set) var isEnabled: Bool

    private let service: any BiometricLockServicing
    private static let enabledKey = "dev.gliadev.MedicAppRemind.appLockEnabled"

    init(service: some BiometricLockServicing = BiometricLockService()) {
        self.service = service
        self.isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    // MARK: - Enable / Disable

    /// Stores the Keychain sentinel and marks the feature as enabled.
    func enable() async throws {
        try await service.storeSentinel()
        isEnabled = true
        UserDefaults.standard.set(true, forKey: Self.enabledKey)
    }

    /// Removes the Keychain sentinel and unlocks immediately.
    func disable() async {
        await service.removeSentinel()
        isEnabled = false
        isLocked = false
        UserDefaults.standard.set(false, forKey: Self.enabledKey)
    }

    // MARK: - Lock / Unlock

    /// Locks the app. No-op when the feature is disabled.
    func lock() {
        guard isEnabled else { return }
        isLocked = true
    }

    /// Triggers the Face ID / Touch ID prompt. Unlocks on success; stays locked on
    /// cancellation or failure — never falls back to a passcode entry inside the app.
    func unlock() async {
        guard isEnabled, isLocked else { return }
        do {
            try await service.authenticate()
            isLocked = false
        } catch {
            // Authentication failed or was cancelled — remain locked.
        }
    }

    var isBiometricsAvailable: Bool {
        get async { await service.isBiometricsAvailable }
    }
}
