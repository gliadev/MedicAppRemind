//
//  MedicationStatCards.swift
//  MedicAppRemind
//
//  F6.S2 — Two-column stat cards (pastillas + días) in the medication detail.
//  Stock state is conveyed by number + StockBadge (icon + text + colour),
//  never colour alone (WCAG 1.4.1). Each card exposes an explicit
//  accessibilityLabel/Value for VoiceOver, replacing the child elements.
//

import SwiftUI

struct MedicationStatCards: View {
    let medication: Medication
    let schedules: [DoseSchedule]
    let stockStatus: StockStatus

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PillsStatCard(medication: medication, stockStatus: stockStatus)
            DaysStatCard(medication: medication, schedules: schedules, stockStatus: stockStatus)
        }
    }
}

// MARK: - Pills card

private struct PillsStatCard: View {
    let medication: Medication
    let stockStatus: StockStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pastillas")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(Int(medication.currentStock), format: .number)
                .font(.system(.largeTitle, weight: .heavy))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            StockBadge(status: stockStatus)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary)
        .clipShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pastillas")
        .accessibilityValue(pillsAccessibilityValue)
    }

    private var pillsAccessibilityValue: String {
        "\(Int(medication.currentStock)), \(stockLevelDescription(stockStatus))"
    }
}

// MARK: - Days card

private struct DaysStatCard: View {
    let medication: Medication
    let schedules: [DoseSchedule]
    let stockStatus: StockStatus

    var body: some View {
        let expiryDate = schedules.first.flatMap {
            medication.refillDate(from: .now, for: $0)
        }

        VStack(alignment: .leading, spacing: 4) {
            Text("Días restantes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(stockStatus.remainingDays ?? 0, format: .number)
                .font(.system(.largeTitle, weight: .heavy))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let expiryDate {
                Text("Se agota el \(Text(expiryDate, format: .dateTime.day().month(.abbreviated)).bold())")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                Text("Sin pauta activa")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary)
        .clipShape(.rect(cornerRadius: 18))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Días restantes")
        .accessibilityValue(daysAccessibilityValue(expiryDate: expiryDate))
    }

    private func daysAccessibilityValue(expiryDate: Date?) -> String {
        let days = stockStatus.remainingDays.map { "\($0) días" } ?? "sin pauta"
        guard let expiryDate else { return days }
        return "\(days), se agota el \(expiryDate.formatted(date: .long, time: .omitted))"
    }
}

// MARK: - Shared helper

private func stockLevelDescription(_ status: StockStatus) -> String {
    switch status.level {
    case .ok:       "\(status.remainingDays ?? 0) días, stock correcto"
    case .low:      "\(status.remainingDays ?? 0) días, stock bajo"
    case .critical: "sin stock"
    case .unknown:  "sin pauta"
    }
}
