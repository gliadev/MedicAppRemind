//
//  QueryRemainingSnippetView.swift
//  MedicAppRemind
//
//  F5.S2 — The visual answer shown alongside the spoken reply for "how much do I
//  have left", on devices that can display a snippet. Dynamic Type only, state
//  carried by icon + text (never colour alone), and the whole card reads as one
//  VoiceOver label.
//

import SwiftUI

/// A compact, accessible summary of a medication's remaining supply.
struct QueryRemainingSnippetView: View {
    let supply: RemainingSupply

    var body: some View {
        VStack(alignment: .leading) {
            Text(supply.medicationName)
                .font(.headline)

            Label {
                Text("\(supply.remainingPills, format: .number) pastillas")
            } icon: {
                Image(systemName: "pills.fill")
            }

            if let days = supply.remainingDays {
                Label {
                    Text("\(days) días de tratamiento")
                } icon: {
                    Image(systemName: "calendar")
                }
            }
        }
        .font(.body)
        .padding()
        .accessibilityElement(children: .combine)
    }
}
