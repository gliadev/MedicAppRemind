//
//  CelebrationOverlay.swift
//  MedicAppRemind
//
//  Celebratory overlay shown once when every dose for the day has been taken.
//  Presents a modal message the user dismisses with "OK", over a continuous
//  confetti rain. Honors Reduce Motion (no flying particles) and drives
//  VoiceOver focus to the message so the milestone is never missed.
//

import SwiftUI

struct CelebrationOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Called when the user dismisses the celebration with the OK button.
    let onFinish: () -> Void

    @AccessibilityFocusState private var messageFocused: Bool

    var body: some View {
        ZStack {
            // Dim backdrop: focuses attention and swallows stray taps so only
            // the OK button dismisses the celebration.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .accessibilityHidden(true)

            if !reduceMotion {
                ConfettiView()
                    .accessibilityHidden(true)
            }

            messageCard
        }
        .task {
            AccessibilityNotification.Announcement(
                String(localized: "¡Has completado todas las tomas de hoy!")
            ).post()
            messageFocused = true
        }
    }

    private var messageCard: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text("¡Enhorabuena!")
                .font(.title.bold())
                .accessibilityFocused($messageFocused)

            Text("Has tomado toda tu medicación de hoy.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onFinish()
            } label: {
                Text("OK")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityHint("Cierra la felicitación")
        }
        .padding(32)
        .frame(maxWidth: 340)
        .background(.regularMaterial, in: .rect(cornerRadius: 28))
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }
}

/// Continuous confetti rain drawn on a single `Canvas`, driven by
/// `TimelineView(.animation)`. Each piece falls on its own looping cycle so the
/// scene stays lively until the user dismisses the card.
private struct ConfettiView: View {
    private struct Piece {
        let x: Double            // horizontal start as a fraction of width (0...1)
        let hue: Double
        let size: Double
        let fall: Double         // seconds for one top-to-bottom fall
        let offset: Double       // phase offset so pieces don't move in lockstep
        let spin: Double         // radians per second
        let sway: Double         // horizontal wobble amplitude in points
    }

    private let pieces: [Piece]
    private let start = Date.now

    init() {
        var rng = SystemRandomNumberGenerator()
        pieces = (0..<160).map { _ in
            Piece(
                x: .random(in: 0...1, using: &rng),
                hue: .random(in: 0...1, using: &rng),
                size: .random(in: 10...22, using: &rng),
                fall: .random(in: 2.0...3.8, using: &rng),
                offset: .random(in: 0...4, using: &rng),
                spin: .random(in: 1...5, using: &rng),
                sway: .random(in: 16...54, using: &rng)
            )
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let elapsed = timeline.date.timeIntervalSince(start)
                for piece in pieces {
                    let progress = ((elapsed + piece.offset) / piece.fall)
                        .truncatingRemainder(dividingBy: 1)
                    let y = -piece.size + progress * (size.height + piece.size * 2)
                    let x = piece.x * size.width
                        + sin((elapsed + piece.offset) * 1.5) * piece.sway

                    var pieceContext = context
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians((elapsed + piece.offset) * piece.spin))

                    let rect = CGRect(
                        x: -piece.size / 2,
                        y: -piece.size * 0.35,
                        width: piece.size,
                        height: piece.size * 0.7
                    )
                    pieceContext.fill(
                        Path(roundedRect: rect, cornerRadius: 2),
                        with: .color(Color(hue: piece.hue, saturation: 0.85, brightness: 0.95))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    CelebrationOverlay(onFinish: {})
}
