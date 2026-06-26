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
        let count = Int(medication.currentStock)
        return String(localized: "\(count), \(stockLevelDescription(stockStatus))")
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
        guard let remaining = stockStatus.remainingDays else {
            return String(localized: "sin pauta")
        }
        let days = dayCountText(remaining)
        guard let expiryDate else { return days }
        let date = expiryDate.formatted(date: .long, time: .omitted)
        return String(localized: "\(days), se agota el \(date)")
    }
}

// MARK: - Shared helper

private func stockLevelDescription(_ status: StockStatus, locale: Locale = .current) -> String {
    let days = dayCountText(status.remainingDays ?? 0, locale: locale)
    var resource: LocalizedStringResource
    switch status.level {
    case .ok:       resource = "\(days), stock correcto"
    case .low:      resource = "\(days), stock bajo"
    case .critical: resource = "sin stock"
    case .unknown:  resource = "sin pauta"
    }
    resource.locale = locale
    return String(localized: resource)
}

#Preview("Stock correcto") {
    let medication = Medication(
        id: UUID(), name: "Atorvastatina", notes: "", form: .pill,
        doseLabel: "20 mg", pillsPerDose: 1, currentStock: 45,
        lowStockThresholdDays: 7, createdAt: .now, updatedAt: .now
    )
    let schedule = DoseSchedule(
        times: [DateComponents(hour: 8, minute: 0)],
        frequency: .daily, startDate: .now
    )
    MedicationStatCards(
        medication: medication,
        schedules: [schedule],
        stockStatus: StockStatus(level: .ok, remainingDays: 45)
    )
    .padding()
}

#Preview("Stock bajo") {
    let medication = Medication(
        id: UUID(), name: "Metformina", notes: "", form: .tablet,
        doseLabel: "500 mg", pillsPerDose: 2, currentStock: 10,
        lowStockThresholdDays: 7, createdAt: .now, updatedAt: .now
    )
    let schedule = DoseSchedule(
        times: [DateComponents(hour: 8, minute: 0), DateComponents(hour: 20, minute: 0)],
        frequency: .daily, startDate: .now
    )
    MedicationStatCards(
        medication: medication,
        schedules: [schedule],
        stockStatus: StockStatus(level: .low, remainingDays: 5)
    )
    .padding()
}
