//
//  MedicationScannerScreen.swift
//  MedicAppRemind
//
//  FX.S3 — Hosts the live code scanner (`CodeScannerView`), routes each detected
//  code to a CIMA lookup, and drives the accessible viewfinder state machine
//  (`ScanViewfinderState`). No autofill is ever silent: a successful lookup shows
//  the confirmation sheet for the user to accept. Every failure lands on a
//  recoverable state — manual entry or retry — and manual entry is always one
//  tap away.
//
//  FX.S5 — A successful lookup now surfaces `ScanConfirmationSheet` (expiry, units,
//  photo, dedup) instead of a minimal inline panel. `.addStock` is written here,
//  directly through the store, the moment the user confirms — `.create` only
//  prefills whichever editor is open; that editor still requires its own explicit
//  "Guardar" before anything is persisted.
//

import SwiftUI
import AVFoundation

struct MedicationScannerScreen: View {
    /// Resolves a scanned identifier against CIMA. Injectable for tests/previews.
    let lookupService: MedicationLookupService
    /// Called once the user confirms the sheet: either a prefill for the open editor,
    /// or notice that stock was already added to an existing medication.
    let onResult: (ScanOutcome) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.medicationStore) private var store
    @State private var state: ScanViewfinderState = .scanning
    @State private var isTorchOn = false
    @State private var hasCamera = true
    @State private var lookupTask: Task<Void, Never>?
    @State private var lastScannedCode: ScannedMedicineCode?

    init(
        lookupService: MedicationLookupService = CIMAService(),
        onResult: @escaping (ScanOutcome) -> Void
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
                .sheet(isPresented: confirmationSheetBinding) {
                    if case .found(let found) = state {
                        ScanConfirmationSheet(
                            found: found,
                            resolvePresentation: resolvePresentation,
                            onCommit: commit,
                            onCancel: reset
                        )
                    }
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
        case .found(.resolved):
            String(localized: "Medicamento encontrado")
        case .found(.choosingPresentation):
            String(localized: "Elige el envase de tu caja")
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

    private var confirmationSheetBinding: Binding<Bool> {
        Binding(
            get: { isFound },
            set: { isPresented in if !isPresented { reset() } }
        )
    }

    // MARK: - Pipeline

    /// Called on the main actor for each distinct detected code.
    private func handle(_ value: String, _ symbology: ScanSymbology) {
        guard state == .scanning,
              let identifier = ScanRouter.identifier(for: value, symbology: symbology) else { return }
        lastScannedCode = ScanRouter.scannedCode(for: value, symbology: symbology)
        state = state.reduced(on: .codeDetected(identifier))
        startLookup(identifier)
    }

    private func startLookup(_ identifier: MedicineIdentifier) {
        lookupTask?.cancel()
        let scannedCode = lastScannedCode
        lookupTask = Task {
            do {
                let medicamento = try await lookupService.medicamento(for: identifier)
                guard !Task.isCancelled else { return }
                let suggestion = MedicationLookupSuggestion(cimaMedicamento: medicamento)
                let photoURL = medicamento.photoURL

                switch identifier {
                case .cn(let cn):
                    let units = try? await presentationUnits(cn: cn)
                    let box = ScannedBox(
                        nationalCode: cn,
                        serial: scannedCode?.serial,
                        units: units,
                        expiry: scannedCode?.expiry.flatMap { GS1Parser.expiryDate(fromYYMMDD: $0) }
                    )
                    let model = await resolvedConfirmation(suggestion: suggestion, box: box, photoURL: photoURL)
                    guard !Task.isCancelled else { return }
                    state = state.reduced(on: .lookupSucceeded(.resolved(model)))

                case .nregistro(let nregistro):
                    let presentations = (try? await lookupService.presentaciones(nregistro: nregistro)) ?? []
                    guard !Task.isCancelled else { return }
                    if presentations.count == 1, let only = presentations.first {
                        let model = await resolvePresentation(only, suggestion: suggestion, photoURL: photoURL)
                        guard !Task.isCancelled else { return }
                        state = state.reduced(on: .lookupSucceeded(.resolved(model)))
                    } else if !presentations.isEmpty {
                        state = state.reduced(on: .lookupSucceeded(
                            .choosingPresentation(suggestion: suggestion, photoURL: photoURL, presentations: presentations)
                        ))
                    } else {
                        state = state.reduced(on: .lookupFailed(.notFound))
                    }
                }
            } catch let error as LookupError {
                state = state.reduced(on: .lookupFailed(error))
            } catch {
                state = state.reduced(on: .lookupFailed(.network))
            }
        }
    }

    private func presentationUnits(cn: String) async throws -> Int? {
        let presentacion = try await lookupService.presentacion(cn: cn)
        return PackageUnitsParser.packageUnits(fromPresentationName: presentacion.nombre)
    }

    /// Resolves a chosen CIMA presentation (the QR route) into a confirmation model,
    /// including the dedup preview — the same path a DataMatrix/EAN-13 scan takes once
    /// its CN is known upfront.
    private func resolvePresentation(
        _ presentation: CIMAPresentacion,
        suggestion: MedicationLookupSuggestion,
        photoURL: URL?
    ) async -> ScanConfirmationModel {
        let box = ScannedBox(
            nationalCode: presentation.cn,
            serial: nil,
            units: PackageUnitsParser.packageUnits(fromPresentationName: presentation.nombre),
            expiry: nil
        )
        return await resolvedConfirmation(suggestion: suggestion, box: box, photoURL: photoURL)
    }

    /// Pairs a box with the store's read-only dedup preview to build the confirmation
    /// model. No store (previews/tests without one wired) degrades to `.create`.
    private func resolvedConfirmation(
        suggestion: MedicationLookupSuggestion,
        box: ScannedBox,
        photoURL: URL?
    ) async -> ScanConfirmationModel {
        let fallback = ScanMergePreview(decision: .create(units: box.units), medicationID: nil, medicationName: nil)
        let preview: ScanMergePreview
        if let store, let result = try? await store.previewScanMerge(nationalCode: box.nationalCode, serial: box.serial) {
            preview = result
        } else {
            preview = fallback
        }
        return scanConfirmation(suggestion: suggestion, box: box, preview: preview, photoURL: photoURL)
    }

    /// The user tapped "Usar datos" (or the equivalent "Sumar stock") in the sheet.
    /// `.addStock` writes immediately, idempotently, through the store; `.create` only
    /// prefills the open editor — its own "Guardar" is still the only thing that
    /// persists it. `.duplicateBox` offers no commit; the sheet never calls back for it.
    private func commit(_ model: ScanConfirmationModel) {
        switch model.action {
        case .create:
            onResult(.prefill(
                name: model.nombre,
                dosis: model.dosis,
                expiryDate: model.expiryDate,
                units: model.units,
                nationalCode: model.nationalCode
            ))
            dismiss()
        case .addStock(_, let medicationName):
            let box = ScannedBox(
                nationalCode: model.nationalCode,
                serial: model.serial,
                units: model.units,
                expiry: model.expiryDate
            )
            Task {
                _ = try? await store?.applyScanMerge(box)
                onResult(.stockAdded(medicationName: medicationName, units: model.units))
                dismiss()
            }
        case .duplicateBox:
            break
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
        lastScannedCode = nil
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
