//
//  MedicationScheduleRow.swift
//  MedicAppRemind
//
//  F6.S2 — List row for a single dose time in the medication's schedule.
//  Icon + time + pills count; VoiceOver reads the combined row as one phrase.
//

import SwiftUI

struct MedicationScheduleRow: View {
    let time: DateComponents
    let pillsPerDose: Double

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: timeOfDaySymbol)
                .font(.title3)
                .foregroundStyle(iconTint)
                .frame(width: 44, height: 44)
                .background(iconBackground)
                .clipShape(.rect(cornerRadius: 12))
                .accessibilityHidden(true)

            Text(timeLabel)
                .font(.body.bold())
                .foregroundStyle(.primary)

            Spacer()

            Text(pillsLabel)
                .font(.body.bold())
                .foregroundStyle(.tint)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    // MARK: - Display helpers

    private var timeLabel: String {
        var comps = time
        comps.year = 2000; comps.month = 1; comps.day = 1
        guard let date = Calendar.current.date(from: comps) else {
            return String(format: "%02d:%02d", time.hour ?? 0, time.minute ?? 0)
        }
        return date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }

    private var pillsLabel: String {
        let n = Int(pillsPerDose)
        return n == 1 ? "1 pastilla" : "\(n) pastillas"
    }

    private var rowAccessibilityLabel: String {
        "\(timeLabel), \(pillsLabel)"
    }

    // MARK: - Time-of-day styling

    private var hour: Int { time.hour ?? 0 }

    private var timeOfDaySymbol: String {
        if hour >= 6 && hour < 14 { return "sun.max.fill" }
        if hour >= 14 && hour < 20 { return "sun.horizon.fill" }
        return "moon.fill"
    }

    private var iconTint: Color {
        if hour >= 6 && hour < 14 { return .orange }
        if hour >= 14 && hour < 20 { return .orange }
        return .indigo
    }

    private var iconBackground: Color {
        if hour >= 6 && hour < 14 { return .orange.opacity(0.15) }
        if hour >= 14 && hour < 20 { return .orange.opacity(0.15) }
        return .indigo.opacity(0.15)
    }
}
