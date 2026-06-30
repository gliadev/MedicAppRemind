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

    // FX diagnostic: surface the RAW payload of every 2D code in view so we can confirm
    // the box reads as a standard QR/DataMatrix before building the GS1 parser + overlay.
    private var captureControls: some View {
        VStack(spacing: 12) {
            if transcripts.isEmpty {
                Text("Apunta al código de la caja")
                    .font(.callout.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: .capsule)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Códigos detectados (\(transcripts.count))")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(Array(transcripts.enumerated()), id: \.offset) { _, payload in
                        Text(payload)
                            .font(.footnote.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: .rect(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Códigos detectados: \(transcripts.joined(separator: ", "))")
            }
        }
        .padding()
    }
}
