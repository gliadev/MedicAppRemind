//
//  BiometricLockError.swift
//  MedicAppRemind
//
//  Security finding #5 — typed errors for the biometric app-lock feature.
//

import Foundation

enum BiometricLockError: LocalizedError {
    case biometricsUnavailable
    case accessControlFailed
    case authenticationFailed
    case sentinelMissing

    var errorDescription: String? {
        switch self {
        case .biometricsUnavailable:
            String(localized: "Face ID o Touch ID no está disponible en este dispositivo.")
        case .accessControlFailed:
            String(localized: "No se pudo configurar el bloqueo. Asegúrate de que el dispositivo tiene código de acceso.")
        case .authenticationFailed:
            String(localized: "No se pudo verificar tu identidad. Inténtalo de nuevo.")
        case .sentinelMissing:
            String(localized: "El bloqueo no está configurado. Actívalo de nuevo en los ajustes.")
        }
    }
}
