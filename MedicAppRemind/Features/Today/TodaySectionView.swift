//
//  TodaySectionView.swift
//  MedicAppRemind
//
//  F6.S1 — One time-period section (Mañana / Mediodía / Noche) in TodayView.
//  The section title is marked `.isHeader` for VoiceOver rotor navigation.
//

import SwiftUI

struct TodaySectionView: View {
    let period: DayPeriod
    let slots: [DoseSlot]
    let onToggle: (DoseSlot) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 6) {
                Text(period.rawValue)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                if let firstTime = slots.first?.scheduledAt {
                    Text(firstTime, format: .dateTime.hour().minute())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(slots) { slot in
                    TodayDoseRow(slot: slot, onToggle: { onToggle(slot) })
                        .padding(.horizontal)
                    if slot.id != slots.last?.id {
                        Divider()
                            .padding(.leading, 74)
                    }
                }
            }
            .background(.regularMaterial, in: .rect(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}
