//
//  NotificationPrivacyTests.swift
//  MedicAppRemindTests
//
//  Security finding #2 — notification bodies must not contain PHI (medication
//  name or dose label) so clinical data never appears on the lock screen.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("NotificationPrivacy")
struct NotificationPrivacyTests {

    private let medicationName = "Atorvastatina"
    private let doseLabel = "20 mg"

    @Test("Dose body does not contain medication name or dose label")
    func doseBodyIsGeneric() {
        let body = NotificationService.notificationBody(for: .dose)
        #expect(!body.localizedStandardContains(medicationName))
        #expect(!body.localizedStandardContains(doseLabel))
        #expect(!body.isEmpty)
    }

    @Test("Low-stock body does not contain medication name or dose label")
    func lowStockBodyIsGeneric() {
        let body = NotificationService.notificationBody(for: .lowStock)
        #expect(!body.localizedStandardContains(medicationName))
        #expect(!body.localizedStandardContains(doseLabel))
        #expect(!body.isEmpty)
    }
}
