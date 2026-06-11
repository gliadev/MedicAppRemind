//
//  DoseNotificationCategory.swift
//  MedicAppRemind
//
//  F3.S3 — The actionable category attached to every dose reminder. Its two
//  actions ("Tomada"/"Posponer") let the patient act straight from the
//  notification, without opening the app. Identifiers are stable strings the
//  delegate matches against; titles are localized.
//

import UserNotifications

/// The action a patient can pick from a dose notification.
///
/// A real enum (cases), not a static-only namespace: the `rawValue` is the
/// stable identifier iOS reports back in the notification response, which the
/// response reducer matches.
enum DoseAction: String, CaseIterable {
    /// Confirms the dose was taken — logs the intake and decrements stock.
    case taken = "DOSE_TAKEN"
    /// Postpones the reminder by `snoozeInterval`.
    case snooze = "DOSE_SNOOZE"

    /// How long "Posponer" pushes the reminder out.
    static let snoozeInterval: Duration = .seconds(600)

    /// The localized button title.
    var title: String {
        switch self {
        case .taken: String(localized: "Tomada")
        case .snooze: String(localized: "Posponer 10 min")
        }
    }

    /// The platform action. Empty options keep it a background action, so tapping
    /// it never brings the app to the foreground — the patient confirms with one tap.
    var notificationAction: UNNotificationAction {
        UNNotificationAction(identifier: rawValue, title: title, options: [])
    }
}

extension UNNotificationCategory {
    /// The category identifier every dose reminder carries, so iOS shows the
    /// `DoseAction` buttons on those notifications.
    static let doseIdentifier = "DOSE_REMINDER"

    /// Builds the dose-reminder category. A factory rather than a stored static:
    /// `UNNotificationCategory` is not `Sendable`, so it can't be a global `let`
    /// without an unsafe opt-out the project forbids. Registered on the
    /// notification center at launch; dose content sets `categoryIdentifier` to
    /// `doseIdentifier`.
    static func makeDose() -> UNNotificationCategory {
        UNNotificationCategory(
            identifier: doseIdentifier,
            actions: DoseAction.allCases.map(\.notificationAction),
            intentIdentifiers: [],
            options: []
        )
    }
}
