//
//  DoseResponse.swift
//  MedicAppRemind
//
//  F3.S3 — The pure decision for "what should happen when the patient interacts
//  with a dose notification". Maps an action identifier + parsed medication id to
//  an outcome, with no UIKit/UserNotifications side effects. The delegate (the
//  effect) dispatches the outcome; this stays unit-tested.
//

import Foundation
import UserNotifications

/// What the app should do in response to a notification interaction.
enum DoseResponse: Equatable, Sendable {
    /// "Tomada": log the intake and decrement stock.
    case recordTaken(medicationID: UUID)
    /// "Posponer": reschedule the reminder shortly after.
    case snooze(medicationID: UUID)
    /// The notification body was tapped: deep-link to the medication's detail.
    case openDetail(medicationID: UUID)
    /// Nothing actionable (dismissed, unknown action, or no medication id).
    case ignore
}

/// Decides the response for a notification interaction.
///
/// - Parameters:
///   - actionIdentifier: the selected action's identifier, as iOS reports it
///     (a `DoseAction.rawValue`, `UNNotificationDefaultActionIdentifier` for a
///     body tap, or `UNNotificationDismissActionIdentifier`).
///   - medicationID: the id parsed from the notification payload, or `nil` if
///     the payload was missing or malformed.
/// - Returns: `.ignore` whenever there is no medication to act on or the action
///   is dismissal/unknown; otherwise the matching outcome.
func doseResponse(actionIdentifier: String, medicationID: UUID?) -> DoseResponse {
    guard let medicationID else { return .ignore }
    switch actionIdentifier {
    case DoseAction.taken.rawValue:
        return .recordTaken(medicationID: medicationID)
    case DoseAction.snooze.rawValue:
        return .snooze(medicationID: medicationID)
    case UNNotificationDefaultActionIdentifier:
        return .openDetail(medicationID: medicationID)
    default:
        // Includes UNNotificationDismissActionIdentifier and any unknown action.
        return .ignore
    }
}
