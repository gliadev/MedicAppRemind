//
//  GS1Parser.swift
//  MedicAppRemind
//
//  FX.S1 — Stateless parser for the GS1 codes on Spanish medicine boxes: the
//  SEVeM DataMatrix payload and the lineal EAN-13 of OTC packages. Pure Swift,
//  TDD'd against payloads decoded from physical boxes (research §5.5).
//

import Foundation

enum GS1Parser {
    /// FNC1 group separator delimiting variable-length AIs (10, 21, 712).
    /// AVFoundation delivers it intact in `stringValue`; without it those
    /// fields would be undelimitable.
    private static let groupSeparator: Character = "\u{1D}"

    /// Parses a raw DataMatrix payload, order-agnostic across AIs (the order
    /// varies between manufacturers). An unknown AI stops parsing and returns
    /// whatever was already read — never a crash, never garbage fields.
    static func parse(_ raw: String) -> ScannedMedicineCode {
        var code = ScannedMedicineCode()
        var rest = Substring(raw)
        if rest.hasPrefix("]d2") { rest = rest.dropFirst(3) }

        while !rest.isEmpty {
            if rest.first == groupSeparator {
                rest = rest.dropFirst()
                continue
            }

            if rest.hasPrefix("01"), rest.count >= 16 {
                code.gtin = String(rest.dropFirst(2).prefix(14))
                rest = rest.dropFirst(16)
            } else if rest.hasPrefix("17"), rest.count >= 8 {
                code.expiry = String(rest.dropFirst(2).prefix(6))
                rest = rest.dropFirst(8)
            } else if rest.hasPrefix("712") {
                let value = rest.dropFirst(3).prefix(while: { $0 != groupSeparator })
                // AI 712 carries CN(6) + EAN check digit: keep the CN, drop the check.
                code.nationalCode = String(value.prefix(6))
                rest = rest.dropFirst(3 + value.count)
            } else if rest.hasPrefix("10") {
                let value = rest.dropFirst(2).prefix(while: { $0 != groupSeparator })
                code.lot = String(value)
                rest = rest.dropFirst(2 + value.count)
            } else if rest.hasPrefix("21") {
                let value = rest.dropFirst(2).prefix(while: { $0 != groupSeparator })
                code.serial = String(value)
                rest = rest.dropFirst(2 + value.count)
            } else {
                break
            }
        }

        if code.nationalCode == nil {
            code.nationalCode = nationalCode(fromNTIN: code.gtin)
        }
        return code
    }

    /// Spanish NTIN route: GTIN-14 = `0` + `847000` + CN(6) + check digit.
    /// Fallback when the payload carried no explicit AI 712.
    private static func nationalCode(fromNTIN gtin: String?) -> String? {
        guard let gtin, gtin.count == 14, gtin.hasPrefix("0847000") else { return nil }
        return String(gtin.dropFirst(7).prefix(6))
    }

    /// Lineal EAN-13 on OTC boxes: `847000` + CN(6) + check digit.
    /// Any other prefix is not an extractable Spanish CN.
    static func nationalCode(fromEAN13 code: String) -> String? {
        guard code.count == 13, code.hasPrefix("847000"), code.allSatisfy(\.isNumber) else { return nil }
        return String(code.dropFirst(6).prefix(6))
    }

    /// AI 17 expiry (`YYMMDD`). GS1 rule: `DD == 00` means the last day of the
    /// month. Days beyond the month's real length are rejected, not rolled over.
    static func expiryDate(
        fromYYMMDD value: String,
        calendar: Calendar = Calendar(identifier: .gregorian)
    ) -> Date? {
        guard value.count == 6, value.allSatisfy(\.isNumber),
              let yy = Int(value.prefix(2)),
              let mm = Int(value.dropFirst(2).prefix(2)),
              let dd = Int(value.suffix(2)),
              (1...12).contains(mm) else { return nil }

        var components = DateComponents(year: 2000 + yy, month: mm, day: 1)
        guard let firstOfMonth = calendar.date(from: components),
              let daysInMonth = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count
        else { return nil }

        switch dd {
        case 0: components.day = daysInMonth
        case 1...daysInMonth: components.day = dd
        default: return nil
        }
        return calendar.date(from: components)
    }
}
