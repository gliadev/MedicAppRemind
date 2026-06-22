//
//  MedicationCalendarSection.swift
//  MedicAppRemind
//
//  F4.S2 — The accessible calendar controls for a medication: a toggle that mirrors
//  doses to the system calendar (reconciling without orphans) and a button that adds
//  a refill reminder. All the work is in CalendarSyncService; this view only reflects
//  state and surfaces failures. Integration is degradable: with no service wired the
//  controls disable instead of crashing.
//

import SwiftUI
import SwiftData

/// Calendar-sync section for the medication detail. Owns the toggle's on/off state and
/// drives the async effect, reverting and reporting on failure. The persisted event
/// identifiers on the model are the source of truth the toggle initializes from.
struct MedicationCalendarSection: View {
    let medication: MedicationModel

    @Environment(\.calendarSync) private var calendarSync

    @State private var isCalendarOn = false
    @State private var isWorking = false
    @State private var errorMessage: String?
    @State private var showPrivacyWarning = false
    @State private var isPendingEnable = false

    var body: some View {
        Section("Calendario") {
            Toggle("Añadir al calendario", isOn: $isCalendarOn)
                .disabled(calendarSync == nil || isWorking)
                .accessibilityHint("Crea o elimina los eventos de tus tomas en el calendario del sistema.")
                .onChange(of: isCalendarOn) { _, newValue in
                    let alreadyMirrored = !medication.calendarEventIDs.isEmpty
                    guard newValue != alreadyMirrored else { return }
                    if newValue && !isPendingEnable {
                        isCalendarOn = false
                        showPrivacyWarning = true
                    } else {
                        isPendingEnable = false
                        Task { await sync(enable: newValue) }
                    }
                }

            Button("Recordar recarga en calendario", systemImage: "calendar.badge.plus") {
                Task { await scheduleRefill() }
            }
            .disabled(calendarSync == nil || isWorking)
        }
        .task(id: medication.id) {
            isCalendarOn = !medication.calendarEventIDs.isEmpty
        }
        .alert(
            "Sincronización con calendario",
            isPresented: $showPrivacyWarning
        ) {
            Button("Continuar") {
                isPendingEnable = true
                isCalendarOn = true
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Los eventos se añadirán al calendario del sistema, que puede estar sincronizado o compartido con otras personas. Los títulos incluirán el nombre del medicamento.")
        }
        .alert(
            "Calendario",
            isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    /// Mirrors or unmirrors the medication, reverting the toggle to the persisted truth
    /// if the effect fails.
    private func sync(enable: Bool) async {
        guard let calendarSync else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await calendarSync.apply(enable ? .enable : .disable, to: medication.id)
        } catch {
            present(error)
            isCalendarOn = !medication.calendarEventIDs.isEmpty
        }
    }

    private func scheduleRefill() async {
        guard let calendarSync else { return }
        isWorking = true
        defer { isWorking = false }
        do {
            try await calendarSync.addRefillReminder(for: medication.id)
        } catch {
            present(error)
        }
    }

    private func present(_ error: Error) {
        errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}

#Preview {
    let controller = try? PersistenceController(inMemory: true)
    if let controller {
        let model: MedicationModel = {
            let m = MedicationModel()
            m.name = "Atorvastatina"
            let context = ModelContext(controller.container)
            context.insert(m)
            try? context.save()
            return m
        }()
        Form {
            MedicationCalendarSection(medication: model)
        }
        .modelContainer(controller.container)
    }
}
