//
//  MedicationScannerScreen.swift
//  MedicAppRemind
//
//  FX.S3 — Hosts the live code scanner (`CodeScannerView`), routes each detected
//  code to a CIMA lookup, and drives the accessible viewfinder state machine
//  (`ScanViewfinderState`). No autofill is ever silent: a successful lookup shows
//  the result for the user to accept. Every failure lands on a recoverable state —
//  manual entry or retry — and manual entry is always one tap away.
//
//  The confirmation sheet with expiry/units/photo (FX.S5) replaces the minimal
//  "found" panel here; this sub-phase proves the code → identifier → lookup path.
//

import SwiftUI
import AVFoundation

struct MedicationScannerScreen: View {
    /// Resolves a scanned identifier against CIMA. Injectable for tests/previews.
    let lookupService: MedicationLookupService
    /// Called when the user accepts a looked-up medicine.
    let onResult: (MedicationLookupSuggestion) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var state: ScanViewfinderState = .scanning
    @State private var isTorchOn = false
    @State private var hasCamera = true
    @State private var lookupTask: Task<Void, Never>?

    init(
        lookupService: MedicationLookupService = CIMAService(),
        onResult: @escaping (MedicationLookupSuggestion) -> Void
    ) {
        self.lookupService = lookupService
        self.onResult = onResult
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Escanear medicamento")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                }
                .task { await prepareCamera() }
                .onDisappear { lookupTask?.cancel() }
                .sensoryFeedback(.success, trigger: isFound)
                .onChange(of: statusMessage) { _, message in
                    AccessibilityNotification.Announcement(message).post()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !hasCamera {
            unavailableView
        } else if state == .cameraDenied {
            permissionDeniedView
        } else {
            scanner
        }
    }

    // MARK: - Scanner

    private var scanner: some View {
        ZStack {
            CodeScannerView(onCode: handle, isTorchOn: isTorchOn)
                .ignoresSafeArea()
            reticle
            VStack(spacing: 16) {
                statusBanner
                Spacer()
                controls
            }
            .padding()
        }
    }

    /// A stable frame that tells the user where to hold the box, without gating
    /// detection (the whole frame is scanned, forgiving for imprecise aiming).
    private var reticle: some View {
        RoundedRectangle(cornerRadius: 20)
            .strokeBorder(.white.opacity(0.9), lineWidth: 3)
            .frame(maxWidth: 280, maxHeight: 200)
            .shadow(radius: 4)
            .accessibilityHidden(true)
    }

    private var statusBanner: some View {
        Text(statusMessage)
            .font(.headline)
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.7), in: .rect(cornerRadius: 12))
            .accessibilityAddTraits(.updatesFrequently)
    }

    @ViewBuilder
    private var controls: some View {
        switch state {
        case .found(let suggestion):
            foundControls(suggestion)
        case .offline:
            offlineControls
        case .notFound:
            notFoundControls
        default:
            scanningControls
        }
    }

    private var scanningControls: some View {
        VStack(spacing: 12) {
            Button(isTorchOn ? "Apagar linterna" : "Encender linterna",
                   systemImage: isTorchOn ? "bolt.slash.fill" : "bolt.fill") {
                isTorchOn.toggle()
            }
            .buttonStyle(.glass)
            .controlSize(.large)

            manualEntryButton
        }
    }

    private func foundControls(_ suggestion: MedicationLookupSuggestion) -> some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(suggestion.nombre)
                    .font(.headline)
                if let dosis = suggestion.dosis {
                    Text(dosis).font(.subheadline)
                }
            }
            .multilineTextAlignment(.center)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.black.opacity(0.7), in: .rect(cornerRadius: 12))
            .accessibilityElement(children: .combine)

            Button("Usar estos datos", systemImage: "checkmark.circle.fill") {
                onResult(suggestion)
                dismiss()
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)

            Button("Escanear otro") { reset() }
                .buttonStyle(.glass)
                .controlSize(.large)
        }
    }

    private var offlineControls: some View {
        VStack(spacing: 12) {
            Button("Reintentar", systemImage: "arrow.clockwise") { retry() }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            manualEntryButton
        }
    }

    private var notFoundControls: some View {
        VStack(spacing: 12) {
            Button("Escanear otro") { reset() }
                .buttonStyle(.glass)
                .controlSize(.large)
            manualEntryButton
        }
    }

    /// Always available: closing the scanner returns to the editor's manual fields.
    private var manualEntryButton: some View {
        Button("Introducir a mano") { dismiss() }
            .buttonStyle(.glass)
            .controlSize(.large)
            .accessibilityHint("Cierra el escáner para escribir los datos tú mismo")
    }

    // MARK: - Fallback views

    private var unavailableView: some View {
        ContentUnavailableView {
            Label("Escáner no disponible", systemImage: "camera.fill")
        } description: {
            Text("Necesitas un dispositivo con cámara. El escáner no funciona en el simulador.")
        } actions: {
            Button("Introducir a mano") { dismiss() }
                .buttonStyle(.glassProminent)
        }
    }

    private var permissionDeniedView: some View {
        ContentUnavailableView {
            Label("Sin acceso a la cámara", systemImage: "camera.fill")
        } description: {
            Text("Para escanear la caja, permite el acceso a la cámara en Ajustes.")
        } actions: {
            if let settings = URL(string: UIApplication.openSettingsURLString) {
                Link("Abrir Ajustes", destination: settings)
                    .buttonStyle(.glassProminent)
            }
            Button("Introducir a mano") { dismiss() }
                .buttonStyle(.glass)
        }
    }

    // MARK: - State

    /// The line VoiceOver reads (and the on-screen banner) for the current state.
    private var statusMessage: String {
        switch state {
        case .scanning:
            String(localized: "Enfoca el código de la caja")
        case .looking:
            String(localized: "Código detectado, buscando el medicamento…")
        case .found:
            String(localized: "Medicamento encontrado")
        case .offline:
            String(localized: "Sin conexión con CIMA")
        case .notFound:
            String(localized: "No se ha encontrado el medicamento. Puedes introducirlo a mano.")
        case .cameraDenied:
            String(localized: "Sin acceso a la cámara")
        }
    }

    private var isFound: Bool {
        if case .found = state { return true }
        return false
    }

    // MARK: - Pipeline

    /// Called on the main actor for each distinct detected code.
    private func handle(_ value: String, _ symbology: ScanSymbology) {
        guard state == .scanning,
              let identifier = ScanRouter.identifier(for: value, symbology: symbology) else { return }
        state = state.reduced(on: .codeDetected(identifier))
        startLookup(identifier)
    }

    private func startLookup(_ identifier: MedicineIdentifier) {
        lookupTask?.cancel()
        lookupTask = Task {
            do {
                let medicamento = try await lookupService.medicamento(for: identifier)
                guard !Task.isCancelled else { return }
                let suggestion = MedicationLookupSuggestion(cimaMedicamento: medicamento)
                state = state.reduced(on: .lookupSucceeded(suggestion))
            } catch let error as LookupError {
                state = state.reduced(on: .lookupFailed(error))
            } catch {
                state = state.reduced(on: .lookupFailed(.network))
            }
        }
    }

    private func retry() {
        state = state.reduced(on: .retry)
        if case .looking(let identifier) = state {
            startLookup(identifier)
        }
    }

    private func reset() {
        lookupTask?.cancel()
        state = state.reduced(on: .reset)
    }

    private func prepareCamera() async {
        hasCamera = AVCaptureDevice.default(for: .video) != nil
        guard hasCamera else { return }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if !granted { state = state.reduced(on: .cameraPermissionDenied) }
        default:
            state = state.reduced(on: .cameraPermissionDenied)
        }
    }
}
