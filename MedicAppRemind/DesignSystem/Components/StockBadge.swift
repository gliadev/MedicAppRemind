//
//  StockBadge.swift
//  MedicAppRemind
//
//  F2.S3 — Non-interactive badge for a medication's remaining supply. State is
//  conveyed by icon AND text AND colour, never colour alone (WCAG 1.4.1).
//  Colours come from the `stock*` tokens; their final contrast is fixed by the
//  F6 accessibility audit.
//

import SwiftUI

struct StockBadge: View {
    let status: StockStatus

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: symbolName)
        }
        .font(.subheadline)
        .foregroundStyle(tint)
    }

    private var days: Int { status.remainingDays ?? 0 }

    private var title: LocalizedStringKey {
        switch status.level {
        case .ok: "\(days) días de stock"
        case .low: "Stock bajo · \(days) días"
        case .critical: "Sin stock"
        case .unknown: "Sin pauta"
        }
    }

    private var symbolName: String {
        switch status.level {
        case .ok: "checkmark.circle"
        case .low: "exclamationmark.triangle"
        case .critical: "xmark.octagon"
        case .unknown: "questionmark.circle"
        }
    }

    private var tint: Color {
        switch status.level {
        case .ok: Color("stockOk")
        case .low: Color("stockLow")
        case .critical: Color("stockCritical")
        case .unknown: .secondary
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        StockBadge(status: StockStatus(level: .ok, remainingDays: 30))
        StockBadge(status: StockStatus(level: .low, remainingDays: 5))
        StockBadge(status: StockStatus(level: .critical, remainingDays: 0))
        StockBadge(status: StockStatus(level: .unknown, remainingDays: nil))
    }
}
