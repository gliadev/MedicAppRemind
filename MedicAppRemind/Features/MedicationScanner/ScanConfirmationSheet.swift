//
//  ScanConfirmationSheet.swift
//  MedicAppRemind
//
//  FX.S5 — The confirmation sheet a successful scan always shows before anything is
//  applied: name, dose, expiry, units and a packaging photo, plus the dedup offer
//  ("Sumar N al stock de X" / "ya escaneada"). The QR route's multi-packaging case
//  resolves its own dedup preview once the user picks a presentation, then renders
//  the same confirmation UI. WCAG AA: every control ≥44pt, labelled, Dynamic Type.
//

import SwiftUI

struct ScanConfirmationSheet: View {
    let found: ScanFoundState
    let resolvePresentation: (CIMAPresentacion, MedicationLookupSuggestion, URL?) async -> ScanConfirmationModel
    let onCommit: (ScanConfirmationModel) -> Void
    let onCancel: () -> Void

    @State private var selectedPresentation: CIMAPresentacion?
    @State private var resolvedFromPresentation: ScanConfirmationModel?
    @State private var isResolvingPresentation = false

    var body: some View {
        NavigationStack {
            Group {
                switch found {
                case .resolved(let model):
                    confirmationForm(model)
                case .choosingPresentation(let suggestion, let photoURL, let presentations):
                    presentationChoiceForm(suggestion: suggestion, photoURL: photoURL, presentations: presentations)
                }
            }
            .navigationTitle("Confirmar medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { onCancel() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Resolved confirmation

    @ViewBuilder
    private func confirmationForm(_ model: ScanConfirmationModel) -> some View {
        Form {
            Section {
                photo(model.photoURL)
                LabeledContent("Nombre") { Text(model.nombre) }
                    .accessibilityElement(children: .combine)
                doseRow(model)
                LabeledContent("Caducidad") { Text(expiryText(model.expiryDate)) }
                    .accessibilityElement(children: .combine)
                LabeledContent("Unidades") { Text(unitsText(model.units)) }
                    .accessibilityElement(children: .combine)
            }
            Section {
                actionRow(model)
            }
        }
    }

    @ViewBuilder
    private func doseRow(_ model: ScanConfirmationModel) -> some View {
        LabeledContent("Dosis") {
            if let dosis = model.dosis {
                Text(dosis)
            } else {
                Text("Indícala tú mismo")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint(model.doseNeedsUserInput ? "Este medicamento tiene varios principios activos; escribe la dosis en el editor" : "")
    }

    @ViewBuilder
    private func actionRow(_ model: ScanConfirmationModel) -> some View {
        switch model.action {
        case .create:
            Button("Usar datos", systemImage: "checkmark.circle.fill") { onCommit(model) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .accessibilityHint("Rellena el editor con estos datos; tendrás que guardar para confirmarlos")

        case .addStock(_, let medicationName):
            Group {
                if let units = model.units {
                    Button("Sumar \(units) uds. al stock de \(medicationName)", systemImage: "plus.circle.fill") {
                        onCommit(model)
                    }
                } else {
                    Button("Sumar esta caja al stock de \(medicationName)", systemImage: "plus.circle.fill") {
                        onCommit(model)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 44)
            .accessibilityHint("Añade esta caja al stock del medicamento ya guardado")

        case .duplicateBox(let medicationName):
            VStack(spacing: 8) {
                Label("Esta caja ya la escaneaste", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.secondary)
                Text("Ya está sumada al stock de \(medicationName).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
    }

    // MARK: - Choosing a presentation (QR route, several packagings)

    @ViewBuilder
    private func presentationChoiceForm(
        suggestion: MedicationLookupSuggestion,
        photoURL: URL?,
        presentations: [CIMAPresentacion]
    ) -> some View {
        Form {
            Section("¿Qué envase es?") {
                photo(photoURL)
                Text(suggestion.nombre)
                    .font(.headline)
                ForEach(presentations, id: \.cn) { presentation in
                    presentationButton(presentation, suggestion: suggestion, photoURL: photoURL)
                }
            }
            if let resolvedFromPresentation {
                Section {
                    actionRow(resolvedFromPresentation)
                }
            }
        }
        .task {
            if selectedPresentation == nil, let first = presentations.first {
                choose(first, suggestion: suggestion, photoURL: photoURL)
            }
        }
    }

    private func presentationButton(
        _ presentation: CIMAPresentacion,
        suggestion: MedicationLookupSuggestion,
        photoURL: URL?
    ) -> some View {
        let isSelected = selectedPresentation == presentation
        return Button {
            choose(presentation, suggestion: suggestion, photoURL: photoURL)
        } label: {
            HStack {
                Text(presentationLabel(presentation))
                Spacer()
                if isSelected {
                    if isResolvingPresentation {
                        ProgressView()
                    } else {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                    }
                }
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(presentationLabel(presentation))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Elige este envase")
    }

    private func choose(_ presentation: CIMAPresentacion, suggestion: MedicationLookupSuggestion, photoURL: URL?) {
        guard selectedPresentation != presentation else { return }
        selectedPresentation = presentation
        resolvedFromPresentation = nil
        isResolvingPresentation = true
        Task {
            let model = await resolvePresentation(presentation, suggestion, photoURL)
            guard selectedPresentation == presentation else { return } // a later pick pre-empted this one
            resolvedFromPresentation = model
            isResolvingPresentation = false
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func photo(_ url: URL?) -> some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFit().frame(maxHeight: 140)
                case .empty:
                    ProgressView().frame(maxWidth: .infinity, minHeight: 80)
                case .failure:
                    EmptyView()
                @unknown default:
                    EmptyView()
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func expiryText(_ date: Date?) -> String {
        guard let date else { return String(localized: "No indicada") }
        return date.formatted(.dateTime.day().month(.wide).year())
    }

    private func unitsText(_ units: Int?) -> String {
        guard let units else { return String(localized: "Indícalas tú mismo") }
        return units.formatted()
    }

    private func presentationLabel(_ presentation: CIMAPresentacion) -> String {
        if let units = PackageUnitsParser.packageUnits(fromPresentationName: presentation.nombre) {
            return String(localized: "\(units) unidades")
        }
        return presentation.nombre
    }
}
