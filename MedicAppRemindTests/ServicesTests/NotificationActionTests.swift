//
//  NotificationActionTests.swift
//  MedicAppRemindTests
//
//  F3.S3 — The notification-response logic is pure and tested here: the intake
//  reducer "Tomada" applies, the action→outcome decision, the deterministic
//  occurrence id behind idempotency, and the payload round-trip. The UIKit/UN
//  delegate itself is not unit-tested — only the reducers it dispatches.
//

import Testing
import Foundation
import UserNotifications
@testable import MedicAppRemind

@Suite("NotificationAction")
struct NotificationActionTests {

    private let medID = UUID(uuidString: "0BADF00D-0000-0000-0000-0000000000AB") ?? UUID()

    // MARK: - recordedDose reducer (shared with F5 App Intents)

    @Test("Confirming a dose logs it taken and decrements by pillsPerDose")
    func recordedDoseLogsTakenAndDecrements() throws {
        // 2 pills per dose → the log records 2 and stock is asked to drop by 2.
        let med = makeMedication(pillsPerDose: 2)
        let scheduled = try isoDate("2026-06-09T09:00:00Z")
        let taken = try isoDate("2026-06-09T09:03:00Z")
        let logID = UUID(uuidString: "0BADF00D-0000-0000-0000-0000000000AA") ?? UUID()

        let recorded = recordedDose(for: med, scheduledAt: scheduled, takenAt: taken, logID: logID)

        #expect(recorded.stockDecrement == 2)
        #expect(recorded.log.id == logID)
        #expect(recorded.log.medicationID == med.id)
        #expect(recorded.log.status == .taken)
        #expect(recorded.log.pillsTaken == 2)
        #expect(recorded.log.scheduledAt == scheduled)
        #expect(recorded.log.takenAt == taken)
    }

    // MARK: - doseResponse decision

    @Test("The Tomada action records a taken dose")
    func takenActionRecordsTaken() {
        #expect(doseResponse(actionIdentifier: DoseAction.taken.rawValue, medicationID: medID)
            == .recordTaken(medicationID: medID))
    }

    @Test("The Posponer action snoozes")
    func snoozeActionSnoozes() {
        #expect(doseResponse(actionIdentifier: DoseAction.snooze.rawValue, medicationID: medID)
            == .snooze(medicationID: medID))
    }

    @Test("Tapping the notification body opens the detail")
    func defaultActionOpensDetail() {
        #expect(doseResponse(actionIdentifier: UNNotificationDefaultActionIdentifier, medicationID: medID)
            == .openDetail(medicationID: medID))
    }

    @Test("Dismissing the notification is ignored")
    func dismissActionIgnored() {
        #expect(doseResponse(actionIdentifier: UNNotificationDismissActionIdentifier, medicationID: medID)
            == .ignore)
    }

    @Test("An unknown action is ignored")
    func unknownActionIgnored() {
        #expect(doseResponse(actionIdentifier: "SOMETHING_ELSE", medicationID: medID) == .ignore)
    }

    @Test("A response without a medication id is ignored even for a known action")
    func missingMedicationIDIgnored() {
        #expect(doseResponse(actionIdentifier: DoseAction.taken.rawValue, medicationID: nil) == .ignore)
    }

    // MARK: - doseOccurrenceID determinism (the basis of idempotency)

    @Test("The same occurrence always yields the same id")
    func occurrenceIDIsDeterministic() throws {
        let date = try isoDate("2026-06-09T09:00:00Z")
        // Re-deriving for the same medication and instant must match — a UUID()
        // implementation would fail this.
        #expect(doseOccurrenceID(medicationID: medID, scheduledAt: date)
            == doseOccurrenceID(medicationID: medID, scheduledAt: date))
    }

    @Test("Different medications get different occurrence ids")
    func occurrenceIDVariesByMedication() throws {
        let date = try isoDate("2026-06-09T09:00:00Z")
        let other = UUID(uuidString: "0BADF00D-0000-0000-0000-0000000000AC") ?? UUID()
        #expect(doseOccurrenceID(medicationID: medID, scheduledAt: date)
            != doseOccurrenceID(medicationID: other, scheduledAt: date))
    }

    @Test("Different scheduled instants get different occurrence ids")
    func occurrenceIDVariesByInstant() throws {
        let morning = try isoDate("2026-06-09T09:00:00Z")
        let evening = try isoDate("2026-06-09T21:00:00Z")
        #expect(doseOccurrenceID(medicationID: medID, scheduledAt: morning)
            != doseOccurrenceID(medicationID: medID, scheduledAt: evening))
    }

    // MARK: - DosePayload

    @Test("The payload round-trips its medication id through userInfo")
    func payloadRoundTrips() {
        let userInfo = DosePayload(medicationID: medID).userInfo
        #expect(userInfo == [DosePayload.medicationIDKey: medID.uuidString])
        #expect(DosePayload(userInfo: userInfo)?.medicationID == medID)
    }

    @Test("A payload with no medication id fails to parse")
    func payloadRejectsMissingKey() {
        #expect(DosePayload(userInfo: [:]) == nil)
    }

    @Test("A payload with a malformed medication id fails to parse")
    func payloadRejectsMalformedID() {
        #expect(DosePayload(userInfo: [DosePayload.medicationIDKey: "not-a-uuid"]) == nil)
    }

    // MARK: - Deep-link routing

    @MainActor
    @Test("Opening a medication deep-link sets the navigation path")
    func routerOpensMedication() {
        let router = AppRouter()
        router.openMedication(medID)
        #expect(router.path == [medID])
    }
}
