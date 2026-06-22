//
//  AppLockMonitorTests.swift
//  MedicAppRemindTests
//
//  Security finding #5 — verifies AppLockMonitor's state machine using mock
//  services. Keychain / Secure Enclave calls are excluded (device-only);
//  these tests cover the lock/unlock logic and the enable/disable transitions.
//

import Testing
import Foundation
@testable import MedicAppRemind

// MARK: - Mocks

struct AlwaysSucceedingLockService: BiometricLockServicing {
    var isBiometricsAvailable: Bool { true }
    func storeSentinel() async throws {}
    func authenticate() async throws {}
    func removeSentinel() async {}
}

// Biometrics unavailable — enable() should throw.
struct UnavailableLockService: BiometricLockServicing {
    var isBiometricsAvailable: Bool { false }
    func storeSentinel() async throws { throw BiometricLockError.biometricsUnavailable }
    func authenticate() async throws { throw BiometricLockError.authenticationFailed }
    func removeSentinel() async {}
}

// Can store the sentinel but authentication always fails (e.g. Face ID rejected).
struct AuthFailingLockService: BiometricLockServicing {
    var isBiometricsAvailable: Bool { true }
    func storeSentinel() async throws {}
    func authenticate() async throws { throw BiometricLockError.authenticationFailed }
    func removeSentinel() async {}
}

// MARK: - Tests

@Suite("AppLockMonitor")
@MainActor
struct AppLockMonitorTests {

    @Test("lock() has no effect when feature is disabled")
    func lockWhenDisabled() {
        let monitor = AppLockMonitor(service: AlwaysSucceedingLockService())
        monitor.lock()
        #expect(monitor.isLocked == false)
    }

    @Test("lock() locks the app when feature is enabled")
    func lockWhenEnabled() async throws {
        let monitor = AppLockMonitor(service: AlwaysSucceedingLockService())
        try await monitor.enable()
        monitor.lock()
        #expect(monitor.isLocked == true)
        await monitor.disable()
    }

    @Test("unlock() clears isLocked after successful authentication")
    func unlockSucceeds() async throws {
        let monitor = AppLockMonitor(service: AlwaysSucceedingLockService())
        try await monitor.enable()
        monitor.lock()
        await monitor.unlock()
        #expect(monitor.isLocked == false)
        await monitor.disable()
    }

    @Test("unlock() keeps isLocked when authentication fails")
    func unlockFails() async throws {
        let monitor = AppLockMonitor(service: AuthFailingLockService())
        try await monitor.enable()
        monitor.lock()
        await monitor.unlock()
        #expect(monitor.isLocked == true)
        await monitor.disable()
    }

    @Test("enable() throws and stays disabled when biometrics are unavailable")
    func enableThrowsWhenUnavailable() async {
        let monitor = AppLockMonitor(service: UnavailableLockService())
        await #expect(throws: BiometricLockError.biometricsUnavailable) {
            try await monitor.enable()
        }
        #expect(monitor.isEnabled == false)
    }

    @Test("disable() unlocks and marks feature as disabled")
    func disableUnlocks() async throws {
        let monitor = AppLockMonitor(service: AlwaysSucceedingLockService())
        try await monitor.enable()
        monitor.lock()
        await monitor.disable()
        #expect(monitor.isEnabled == false)
        #expect(monitor.isLocked == false)
    }
}
