//
//  DescribeMedicationSheet.swift
//  MedicAppRemind
//
//  F10.S3 — The "Describir" sheet: a multiline field (system dictation comes
//  free with the keyboard), one primary action, and the single kind failure
//  message. WCAG AA: controls ≥44pt and labelled, Dynamic Type, VoiceOver
//  announcements on completion and failure, always cancelable.
//

import SwiftUI

@MainActor
struct DescribeMedicationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.draftParser) private var parser

    /// Receives the outcome exactly once, right before the sheet dismisses.
    let onResult: (DescribeFlowResult) -> Void

    @State private var text = ""
    @State private var state = DescribeSheetState.idle
    @State private var parseTask: Task<Void, Never>?

    /// Three-ish body lines at standard type; grows with Dynamic Type (AX).
    @ScaledMetric(relativeTo: .body) private var editorMinHeight: CGFloat = 88

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // TextEditor, not TextField(axis: .vertical): the multiline
                    // TextField drops keyboard dictation after the first letter
                    // on device (F10.S4 matrix finding; Apple Forums #128721).
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .frame(minHeight: editorMinHeight)
                            .disabled(state == .loading)
                            .accessibilityLabel("Descripción del medicamento")
                            .accessibilityHint("Escribe o dicta el medicamento, la pauta y las pastillas que te quedan")
                        if text.isEmpty {
                            Text("Ej. Ibuprofeno 600, una cada 8 horas, me quedan 30")
                                .foregroundStyle(.secondary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                } header: {
                    Text("Describe tu medicación")
                } footer: {
                    if state == .failed {
                        Text(DraftParserError.couldNotParse.errorDescription ?? "")
                            .foregroundStyle(.red)
                            .accessibilityLabel("Error: \(DraftParserError.couldNotParse.errorDescription ?? "")")
                    } else {
                        Text("Con tus palabras: qué tomas, cuándo y cuántas te quedan. Tú revisas los datos antes de guardar.")
                    }
                }

                Section {
                    interpretButton()
                    if state == .failed {
                        Button("Rellenar a mano", systemImage: "square.and.pencil") {
                            finishToManualEntry()
                        }
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityHint("Cierra esta hoja; tu texto queda guardado en las notas del medicamento")
                    }
                }
            }
            .navigationTitle("Describir medicación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { cancel() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear { parseTask?.cancel() }
    }

    @ViewBuilder
    private func interpretButton() -> some View {
        Button {
            interpret()
        } label: {
            if state == .loading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Interpretando tu descripción…")
                }
                .frame(maxWidth: .infinity, minHeight: 44)
            } else {
                Label(
                    state == .failed ? "Volver a intentarlo" : "Interpretar",
                    systemImage: "wand.and.stars"
                )
                .frame(maxWidth: .infinity, minHeight: 44)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(state == .loading || !text.contains { !$0.isWhitespace })
        .accessibilityHint("Convierte tu descripción en los campos del medicamento")
    }

    // MARK: - Actions

    private func interpret() {
        let next = state.reduced(on: .interpretTapped(text: text))
        guard next == .loading, state != .loading else { return }
        state = next

        parseTask = Task {
            guard let parser else {
                // Availability lost between opening and tapping: same single path.
                state = state.reduced(on: .parseFailed)
                return
            }
            let result = await describeFlowResult(text: text, parser: parser)
            guard !Task.isCancelled, state == .loading else { return }
            switch result {
            case .prefill:
                state = state.reduced(on: .parseSucceeded)
                onResult(result)
                dismiss()
            case .failed:
                state = state.reduced(on: .parseFailed)
                AccessibilityNotification.Announcement(
                    DraftParserError.couldNotParse.errorDescription ?? ""
                ).post()
            }
        }
    }

    /// After a failure, leaving to manual entry still preserves the text.
    private func finishToManualEntry() {
        parseTask?.cancel()
        onResult(.failed(notesText: text))
        dismiss()
    }

    private func cancel() {
        parseTask?.cancel()
        let wasFailed = (state == .failed)
        state = state.reduced(on: .cancelled)
        if wasFailed {
            onResult(.failed(notesText: text))
        }
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    DescribeMedicationSheet { _ in }
        .environment(\.draftParser, nil)
}
