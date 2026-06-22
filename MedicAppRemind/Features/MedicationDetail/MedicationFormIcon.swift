//
//  MedicationFormIcon.swift
//  MedicAppRemind
//
//  F6.S2 — Rounded icon for a medication's physical form, used in the detail header.
//  Hidden from VoiceOver — the medication name in the header carries the identity.
//

import SwiftUI

struct MedicationFormIcon: View {
    let form: MedicationForm
    @ScaledMetric(relativeTo: .title2) private var size: CGFloat = 60

    var body: some View {
        Image(systemName: symbolName)
            .font(.title2)
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.15))
            .clipShape(.rect(cornerRadius: size * 0.285))
            .accessibilityHidden(true)
    }

    private var symbolName: String {
        switch form {
        case .pill:      "pills.fill"
        case .capsule:   "capsule.fill"
        case .tablet:    "rectangle.fill"
        case .liquid:    "drop.fill"
        case .injection: "syringe.fill"
        case .other:     "cross.fill"
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        ForEach(MedicationForm.allCases, id: \.self) { form in
            MedicationFormIcon(form: form)
        }
    }
    .padding()
}
