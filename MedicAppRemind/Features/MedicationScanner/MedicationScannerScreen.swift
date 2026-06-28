//
//  MedicationScannerScreen.swift
//  MedicAppRemind
//
//  v1.2 — Presents the live medication-box scanner and hands a parsed `ScannedMedication`
//  back to the editor. Gated on `DataScannerViewController.isSupported` so the simulator and
//  unsupported devices show a clear message instead of a black camera.
//

import SwiftUI
import VisionKit

struct MedicationScannerScreen: View {
    /// Called with the parsed suggestion when the user confirms a scan.
    let onResult: (ScannedMedication) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var transcripts: [String] = []

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Escanear caja")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if DataScannerViewController.isSupported {
            scanner
        } else {
            ContentUnavailableView {
                Label("Escáner no disponible", systemImage: "camera.fill")
            } description: {
                Text("Necesitas un dispositivo con cámara. El escáner no funciona en el simulador.")
            }
        }
    }

    private var scanner: some View {
        ZStack(alignment: .bottom) {
            MedicationScannerView(transcripts: $transcripts)
                .ignoresSafeArea()
            captureControls
        }
    }

    private var captureControls: some View {
        VStack(spacing: 12) {
            if let preview {
                Text(preview)
                    .font(.callout.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: .capsule)
                    .accessibilityLabel("Detectado: \(preview)")
            }
            Button("Usar texto detectado", systemImage: "checkmark.circle.fill") {
                onResult(ScannedMedication(recognizedLines: transcripts))
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(suggestion.isEmpty)
            .accessibilityHint("Rellena el nombre y la dosis con el texto detectado")
        }
        .padding()
    }

    /// The current parse of what the camera sees, recomputed as transcripts change.
    private var suggestion: ScannedMedication {
        ScannedMedication(recognizedLines: transcripts)
    }

    /// A short "Name · dose" preview of what confirming would fill, or `nil` when nothing
    /// usable is in view yet.
    private var preview: String? {
        let parts = [suggestion.name, suggestion.dose].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}
