//
//  BootstrapTests.swift
//  MedicAppRemindTests
//
//  F0.S1 — Smoke tests: verify Swift Testing runs and the build identity is correct.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Bootstrap")
struct BootstrapTests {

    /// Smoke test: confirms the Swift Testing harness is wired up and runs.
    @Test("Swift Testing is available")
    func swiftTestingIsAvailable() {
        #expect(true)
    }

    /// Forces reading the host app bundle identifier and confirms it matches the
    /// project constant. The unit-test target is hosted by the app, so
    /// `Bundle.main` resolves to the app bundle.
    @Test("App bundle identifier matches the project constant")
    func bundleIdentifierIsExpected() throws {
        let bundleID = try #require(Bundle.main.bundleIdentifier)
        #expect(bundleID == "dev.gliadev.MedicAppRemind")
    }
}
