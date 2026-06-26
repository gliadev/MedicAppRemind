//
//  DayCount.swift
//  MedicAppRemind
//
//  Localized day-count fragments. Singular only for exactly one day; in Spanish
//  the article also agrees ("un día" vs "unos N días"), which is why the whole
//  fragment is localized rather than just the number. Shared so the plural rule
//  lives in one place.
//

import Foundation

/// Approximate day count for the "remaining supply" phrase, e.g. "un día" /
/// "unos 5 días" (ES), "1 day" / "5 days" (EN).
func approxDaysText(_ days: Int, locale: Locale = .current) -> String {
    var resource: LocalizedStringResource = days == 1 ? "un día" : "unos \(days) días"
    resource.locale = locale
    return String(localized: resource)
}

/// Plain day count, e.g. "1 día" / "5 días" (ES), "1 day" / "5 days" (EN). For
/// labels that already provide the surrounding context (e.g. a "Días restantes"
/// header), so the value itself stays terse.
func dayCountText(_ days: Int, locale: Locale = .current) -> String {
    var resource: LocalizedStringResource = days == 1 ? "1 día" : "\(days) días"
    resource.locale = locale
    return String(localized: resource)
}

/// Treatment day count, e.g. "1 día de tratamiento" / "5 días de tratamiento"
/// (ES), "1 day of treatment" / "5 days of treatment" (EN).
func treatmentDaysText(_ days: Int, locale: Locale = .current) -> String {
    var resource: LocalizedStringResource = days == 1
        ? "1 día de tratamiento"
        : "\(days) días de tratamiento"
    resource.locale = locale
    return String(localized: resource)
}
