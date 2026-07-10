//
//  CodeScannerView.swift
//  MedicAppRemind
//
//  FX.S3 — Justified UIKit bridge: AVFoundation's capture pipeline has no SwiftUI
//  form. Runs an `AVCaptureSession` feeding an `AVCaptureMetadataOutput` limited to
//  the three medicine-box symbologies and forwards each distinct code to `onCode`
//  on the main actor. AVFoundation is required (over VisionKit) because it delivers
//  the GS1 group separator (\u{1D}) intact in `stringValue` — see ADR-04.
//
//  Concurrency (ADR-04): AVFoundation's metadata delegate demands a serial
//  `DispatchQueue` (no async API exists), and `startRunning()` is a blocking call
//  Apple mandates run off-main on a serial queue. This one `captureQueue` owns both:
//  session config/start/stop AND the delegate callback. The controller is
//  `@unchecked Sendable` — a reasoned, approved exception, not a race hidden: the
//  session self-synchronises (documented; every Apple sample shares it across
//  main↔queue like this), our only mutable Swift state (`debouncer`, cached device)
//  is touched only on `captureQueue`, and `session`/`onCode` are immutable lets.
//

import SwiftUI
import AVFoundation

struct CodeScannerView: UIViewRepresentable {
    /// Called on the main actor with each newly-detected code and its symbology.
    let onCode: @MainActor @Sendable (String, ScanSymbology) -> Void
    /// Whether the torch should be lit.
    var isTorchOn: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(onCode: onCode) }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer?.videoGravity = .resizeAspectFill
        context.coordinator.start(previewLayer: view.previewLayer)
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        context.coordinator.setTorch(on: isTorchOn)
    }

    static func dismantleUIView(_ view: PreviewView, coordinator: Coordinator) {
        coordinator.stop()
    }

    /// A `UIView` whose backing layer is the capture preview layer, so the camera
    /// feed resizes with the view automatically.
    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer? { layer as? AVCaptureVideoPreviewLayer }
    }

    /// Owns the capture pipeline and forwards codes. See the file-level note for why
    /// `@unchecked Sendable` is sound here.
    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, @unchecked Sendable {
        private let captureQueue = DispatchQueue(label: "dev.gliadev.MedicAppRemind.scanner")
        private let session = AVCaptureSession()
        private let onCode: @MainActor @Sendable (String, ScanSymbology) -> Void

        // Touched only on captureQueue.
        private var debouncer = ScanDebouncer()
        private var captureDevice: AVCaptureDevice?
        private var isConfigured = false

        init(onCode: @escaping @MainActor @Sendable (String, ScanSymbology) -> Void) {
            self.onCode = onCode
            super.init()
        }

        /// Attaches the live preview (main) and configures + starts the session
        /// off-main. `session` is a stable `let`, so wiring it to the preview layer
        /// from the main actor is safe.
        func start(previewLayer: AVCaptureVideoPreviewLayer?) {
            previewLayer?.session = session
            captureQueue.async { [self] in
                configureIfNeeded()
                if !session.isRunning { session.startRunning() }
            }
        }

        func stop() {
            captureQueue.async { [self] in
                if session.isRunning { session.stopRunning() }
            }
        }

        func setTorch(on: Bool) {
            captureQueue.async { [self] in
                guard let device = captureDevice, device.hasTorch else { return }
                do {
                    try device.lockForConfiguration()
                    device.torchMode = on ? .on : .off
                    device.unlockForConfiguration()
                } catch {
                    // Torch is a convenience; a locked device just means no light.
                }
            }
        }

        /// Builds the pipeline once. Runs on `captureQueue`. `metadataObjectTypes`
        /// must be assigned only after the output is added to the session.
        private func configureIfNeeded() {
            guard !isConfigured else { return }
            isConfigured = true

            session.beginConfiguration()
            defer { session.commitConfiguration() }
            session.sessionPreset = .high

            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input) else { return }
            session.addInput(input)
            captureDevice = device

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else { return }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: captureQueue)
            output.metadataObjectTypes = ScanSymbology.scannedMetadataTypes.filter(
                output.availableMetadataObjectTypes.contains
            )
        }

        // MARK: - AVCaptureMetadataOutputObjectsDelegate (runs on captureQueue)

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            for object in metadataObjects {
                guard let readable = object as? AVMetadataMachineReadableCodeObject,
                      let value = readable.stringValue,
                      let symbology = ScanSymbology(metadataType: readable.type),
                      debouncer.shouldHandle(value) else { continue }
                let forward = onCode
                Task { @MainActor in forward(value, symbology) }
            }
        }
    }
}
