//
//  PillCount.swift
//  MedicAppRemind
//
//  Localized "N pastilla(s)" fragment. Singular only for exactly one pill;
//  everything else (0, 2, fractional…) reads plural, per ES/EN grammar. Shared
//  by the detail UI, the Siri/Shortcuts dialogs and the VoiceOver announcement
//  so the plural rule lives in one place.
//

import Foundation

/// Localized pill count, e.g. "1 pastilla" / "5 pastillas" (ES), "1 pill" /
/// "5 pills" (EN).
///
/// - Parameters:
///   - count: pill count; values other than exactly one use the plural form.
///   - locale: drives both the number format and the plural lookup; injectable
///     for deterministic tests, defaults to the user's locale.
func pillCountText(_ count: Double, locale: Locale = .current) -> String {
    let formatted = count.formatted(.number.locale(locale))
    var resource: LocalizedStringResource = count == 1
        ? "\(formatted) pastilla"
        : "\(formatted) pastillas"
    resource.locale = locale
    return String(localized: resource)
}
