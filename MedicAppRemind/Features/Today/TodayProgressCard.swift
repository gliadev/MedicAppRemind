//
//  TodayProgressCard.swift
//  MedicAppRemind
//
//  F6.S1 — Day-level progress summary shown at the top of TodayView.
//  A single accessibility element for VoiceOver (the card reads as one unit),
//  with a progress bar that exposes both a label and a numeric value.
//

import SwiftUI

struct TodayProgressCard: View {
    let slots: [DoseSlot]

    private var total: Int { slots.count }
    private var done: Int { slots.filter(\.isTaken).count }
    private var progress: Double { total > 0 ? Double(done) / Double(total) : 0 }
    private var remaining: Int { total - done }

    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .firstTextBaseline) {
                Text("Progreso del día")
                    .font(.headline)
                Spacer()
                Text("\(done) de \(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .accessibilityLabel("Progreso")
                .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
            Text(remainingLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }

    private var remainingLabel: String {
        switch remaining {
        case 0: "¡Todo tomado por hoy!"
        case 1: "Queda 1 toma pendiente"
        default: "Quedan \(remaining) tomas pendientes"
        }
    }

    private var accessibilityDescription: String {
        "\(done) de \(total) tomas completadas. \(remainingLabel)"
    }
}
