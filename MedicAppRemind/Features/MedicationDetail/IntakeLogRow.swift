//
//  IntakeLogRow.swift
//  MedicAppRemind
//
//  F6.S2 — List row for an intake log entry in the medication detail history.
//  Status communicated by icon + text + colour, never colour alone (WCAG 1.4.1).
//

import SwiftUI

struct IntakeLogRow: View {
    let log: IntakeLog

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusTint)
                .frame(width: 34, height: 34)
                .overlay {
                    Image(systemName: statusSymbol)
                        .foregroundStyle(.white)
                        .font(.callout.weight(.semibold))
                }
                .accessibilityHidden(true)

            Text(dateLabel)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer()

            Text(statusTitle)
                .font(.callout.bold())
                .foregroundStyle(statusTint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    // MARK: - Date label

    private var dateLabel: String {
        let calendar = Calendar.current
        let time = log.scheduledAt.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        if calendar.isDateInToday(log.scheduledAt) {
            return "Hoy · \(time)"
        } else if calendar.isDateInYesterday(log.scheduledAt) {
            return "Ayer · \(time)"
        } else {
            let date = log.scheduledAt.formatted(date: .abbreviated, time: .omitted)
            return "\(date) · \(time)"
        }
    }

    // MARK: - Status presentation

    private var statusTitle: LocalizedStringKey {
        switch log.status {
        case .taken:   "Tomada"
        case .missed:  "Omitida"
        case .skipped: "Pospuesta"
        case .pending: "Pendiente"
        }
    }

    private var statusSymbol: String {
        switch log.status {
        case .taken:             "checkmark"
        case .missed, .skipped:  "xmark"
        case .pending:           "clock"
        }
    }

    private var statusTint: Color {
        switch log.status {
        case .taken:   .green
        case .missed:  .red
        case .skipped: .orange
        case .pending: .secondary
        }
    }

    // MARK: - VoiceOver

    private var rowAccessibilityLabel: String {
        "\(dateLabel), \(statusAccessibilityText)"
    }

    private var statusAccessibilityText: String {
        switch log.status {
        case .taken:   "tomada"
        case .missed:  "omitida"
        case .skipped: "pospuesta"
        case .pending: "pendiente"
        }
    }
}
