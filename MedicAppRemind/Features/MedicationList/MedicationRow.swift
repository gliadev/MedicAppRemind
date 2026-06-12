//
//  MedicationRow.swift
//  MedicAppRemind
//
//  F6.S1 — Audited for WCAG 2.2 AA:
//  - `.accessibilityElement(children: .combine)` exposes the whole row as one
//    VoiceOver unit (name + dose + remaining days + stock level).
//  - In accessibility sizes (AX1–AX5) the row expands to full width so Dynamic
//    Type text can wrap freely; no layout breaks at AX5.
//  - Stock state is communicated by icon + text + colour (never colour alone,
//    WCAG 1.4.1) — delegated to `StockBadge`.
//  - Touch target is guaranteed ≥ 44 pt by the wrapping `NavigationLink`.
//

import SwiftUI

struct MedicationRow: View {
    let model: MedicationModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let medication = model.toDomain()
        let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
        let stockStatus = medication.stockStatus(for: schedules)

        VStack(alignment: .leading) {
            Text(medication.name)
                .font(.headline)
            if !medication.doseLabel.isEmpty {
                Text(medication.doseLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            StockBadge(status: stockStatus)
        }
        .frame(
            maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil,
            alignment: .leading
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowLabel(medication: medication, schedules: schedules))
        .accessibilityValue(rowValue(stockStatus: stockStatus))
    }

    private func rowLabel(medication: Medication, schedules: [DoseSchedule]) -> String {
        guard let first = schedules.first else {
            return medication.doseLabel.isEmpty
                ? medication.name
                : "\(medication.name), \(medication.doseLabel)"
        }
        return medication.accessibilityDescription(for: first)
    }

    private func rowValue(stockStatus: StockStatus) -> String {
        stockStatus.remainingDays.map { "\($0) días" } ?? ""
    }
}
