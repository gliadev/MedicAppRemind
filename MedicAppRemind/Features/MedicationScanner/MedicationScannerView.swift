//
//  MedicationScannerView.swift
//  MedicAppRemind
//
//  v1.3 (FX diagnostic) — Justified UIKit bridge: VisionKit's `DataScannerViewController`
//  has no SwiftUI equivalent. Reads the 2D codes (QR + DataMatrix) printed on a medication
//  box and streams their raw payloads into `transcripts`. This is the go/no-go probe to
//  confirm the box's code is a standard symbology (not a proprietary colour code) before
//  migrating to AVFoundation + GS1 parsing. On-device, no network. Requires
//  `NSCameraUsageDescription`.
//

import SwiftUI
import VisionKit
import Vision

struct MedicationScannerView: UIViewControllerRepresentable {
    /// The latest text transcripts the scanner sees, newest snapshot each update.
    @Binding var transcripts: [String]

    func makeCoordinator() -> Coordinator { Coordinator(transcripts: $transcripts) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr, .dataMatrix])],
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
                        if case .barcode(let barcode) = item { return barcode.payloadStringValue }
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
