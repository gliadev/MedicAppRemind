//
//  MedicationRow.swift
//  MedicAppRemind
//
//  F2.S3 — One row of the medication list. Maps its persistence model to domain
//  and derives the stock badge. A separate `View` struct rather than a computed
//  property on the list view.
//

import SwiftUI

struct MedicationRow: View {
    let model: MedicationModel

    var body: some View {
        let medication = model.toDomain()
        let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }

        VStack(alignment: .leading) {
            Text(medication.name)
                .font(.headline)
            if !medication.doseLabel.isEmpty {
                Text(medication.doseLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            StockBadge(status: medication.stockStatus(for: schedules))
        }
    }
}
