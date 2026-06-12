//
//  TodayDoseRow.swift
//  MedicAppRemind
//
//  F6.S1 — One dose row in TodayView. Tapping marks the dose as taken
//  (idempotent via occurrence ID). State is communicated by icon + text +
//  colour, never colour alone (WCAG 1.4.1). The whole row is a single Button
//  so VoiceOver reads it as one action with a combined label.
//

import SwiftUI

struct TodayDoseRow: View {
    let slot: DoseSlot
    let onToggle: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: onToggle) {
            if dynamicTypeSize.isAccessibilitySize {
                // AX layout: stack icon + status on top, name + dose below
                VStack(alignment: .leading) {
                    HStack(spacing: 10) {
                        circleIcon
                        statusBadge
                        Spacer()
                    }
                    Text(slot.medicationName)
                        .font(.headline)
                    Text(slot.doseLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                // Standard layout: icon | name/dose | status badge
                HStack(spacing: 14) {
                    circleIcon
                    VStack(alignment: .leading) {
                        Text(slot.medicationName)
                            .font(.headline)
                        Text(slot.doseLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusBadge
                }
                .padding(.vertical, 4)
            }
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        // Single combined label for VoiceOver: name + dose + time + status
        .accessibilityLabel(voiceOverLabel)
        .accessibilityHint(
            slot.isTaken
                ? String(localized: "Toma ya registrada")
                : String(localized: "Pulsa para registrar la toma")
        )
        .accessibilityAddTraits(slot.isTaken ? .isSelected : [])
    }

    // MARK: - Sub-views

    /// Circle indicator — decorative, covered by the button's accessibilityLabel.
    private var circleIcon: some View {
        Image(systemName: slot.isTaken ? "checkmark.circle.fill" : "circle")
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(slot.isTaken ? Color("stockOk") : Color.secondary)
            .imageScale(.large)
            .frame(width: 44, height: 44)
            .accessibilityHidden(true)
    }

    /// Status badge: icon + text, never colour alone (WCAG 1.4.1).
    /// Hidden from VoiceOver; the button label already conveys the state.
    private var statusBadge: some View {
        HStack(spacing: 4) {
            if slot.isTaken {
                Image(systemName: "checkmark")
                    .imageScale(.small)
                    .foregroundStyle(Color("stockOk"))
            }
            Text(slot.isTaken ? "Tomada" : "Pendiente")
                .font(.subheadline)
                .bold(slot.isTaken)
                .foregroundStyle(slot.isTaken ? Color("stockOk") : Color("stockLow"))
        }
        .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private var voiceOverLabel: String {
        let time = slot.scheduledAt.formatted(date: .omitted, time: .shortened)
        let status = slot.isTaken ? "Tomada" : "Pendiente"
        return "\(slot.medicationName), \(slot.doseLabel), \(time), \(status)"
    }
}
