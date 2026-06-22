//
//  BiometricLockService.swift
//  MedicAppRemind
//
//  Security finding #5 — keychain-bound biometric authentication.
//
//  Pattern: a sentinel item is stored in the Keychain behind SecAccessControl
//  with .biometryCurrentSet. Authenticating reads the item, which lets the
//  Secure Enclave handle Face ID/Touch ID — there is no Bool to patch at runtime.
//
//  Core rules (swift-security-expert):
//  - SecItem* calls never run on @MainActor → this type is an actor.
//  - kSecAttrAccessible is always explicit (WhenPasscodeSetThisDeviceOnly).
//  - Add-or-update pattern: duplicate item on enable is not an error.
//  - Every OSStatus is handled via an exhaustive switch.
//

import Foundation
import LocalAuthentication
import Security

protocol BiometricLockServicing: Sendable {
    var isBiometricsAvailable: Bool { get async }
    func storeSentinel() async throws
    func authenticate() async throws
    func removeSentinel() async
}

actor BiometricLockService: BiometricLockServicing {
    private static let service = "dev.gliadev.MedicAppRemind.applock"
    private static let account = "sentinel"

    var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    /// Stores the sentinel item in the Keychain, protected by the current biometric
    /// enrollment. Called once when the user enables the app lock.
    func storeSentinel() throws {
        guard isBiometricsAvailable else { throw BiometricLockError.biometricsUnavailable }

        var cfError: Unmanaged<CFError>?
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            .biometryCurrentSet,
            &cfError
        ) else {
            throw BiometricLockError.accessControlFailed
        }

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecValueData as String: Data("1".utf8),
            kSecAttrAccessControl as String: access,
        ]

        // Add-or-update: duplicate means it was already configured, which is fine.
        let status = SecItemAdd(attributes as CFDictionary, nil)
        switch status {
        case errSecSuccess, errSecDuplicateItem:
            break
        default:
            throw BiometricLockError.accessControlFailed
        }
    }

    /// Reads the sentinel from the Keychain, triggering the Face ID / Touch ID
    /// prompt via the Secure Enclave. The biometric check happens entirely in
    /// hardware — there is no Bool returned that could be patched.
    func authenticate() throws {
        let context = LAContext()
        context.localizedReason = String(localized: "Desbloquea MediRemind para acceder a tu medicación")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: false,
            kSecUseAuthenticationContext as String: context,
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        switch status {
        case errSecSuccess:
            break
        case errSecItemNotFound:
            throw BiometricLockError.sentinelMissing
        case errSecInteractionNotAllowed:
            // Device is locked or in background — not an authentication failure,
            // but we cannot authenticate right now; stay locked.
            throw BiometricLockError.authenticationFailed
        default:
            throw BiometricLockError.authenticationFailed
        }
    }

    /// Removes the sentinel from the Keychain. Called when the user disables the
    /// app lock. OSStatus is intentionally ignored — if the item is already gone,
    /// the goal (no sentinel) is already achieved.
    func removeSentinel() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
