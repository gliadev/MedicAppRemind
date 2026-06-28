//
//  MedicationScannerView.swift
//  MedicAppRemind
//
//  v1.2 — Justified UIKit bridge: VisionKit's `DataScannerViewController` has no SwiftUI
//  equivalent. Streams the live text it recognises on a medication box into `transcripts`;
//  the presenting screen parses those lines (`ScannedMedication`) only when the user
//  confirms. On-device, no network. Requires `NSCameraUsageDescription`.
//

import SwiftUI
import VisionKit

struct MedicationScannerView: UIViewControllerRepresentable {
    /// The latest text transcripts the scanner sees, newest snapshot each update.
    @Binding var transcripts: [String]

    func makeCoordinator() -> Coordinator { Coordinator(transcripts: $transcripts) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .accurate,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.start(scanner)
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
        coordinator.stop()
    }

    @MainActor
    final class Coordinator {
        @Binding private var transcripts: [String]
        private var streamTask: Task<Void, Never>?

        init(transcripts: Binding<[String]>) {
            _transcripts = transcripts
        }

        /// Starts scanning once and mirrors the recognized text items into `transcripts`.
        func start(_ scanner: DataScannerViewController) {
            guard streamTask == nil else { return }
            try? scanner.startScanning()
            streamTask = Task { [weak self, weak scanner] in
                guard let scanner else { return }
                for await items in scanner.recognizedItems {
                    self?.transcripts = items.compactMap { item in
                        if case .text(let text) = item { return text.transcript }
                        return nil
                    }
                }
            }
        }

        func stop() {
            streamTask?.cancel()
            streamTask = nil
        }
    }
}
