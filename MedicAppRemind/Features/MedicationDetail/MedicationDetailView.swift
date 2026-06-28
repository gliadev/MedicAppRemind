//
//  MedicationDetailView.swift
//  MedicAppRemind
//
//  F6.S2 — Real medication detail screen. Replaces the F3.S3/F4.S2 placeholder.
//  Layout follows Screen 02 of docs/design-mockups. WCAG 2.2 AA audited:
//  • Button "Registrar toma" carries text + systemImage label.
//  • accessibilityHint on the primary action.
//  • VoiceOver announcement via AccessibilityNotification.Announcement after recording.
//  • accessibilityAction(named:) on header for rotor (Editar — wired in F6.S3).
//  • safeAreaInset background adapts automatically to accessibilityReduceTransparency.
//  • AnyLayout adapts header to stacked layout at AX5 Dynamic Type sizes.
//

import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    @Query private var medications: [MedicationModel]

    @Environment(\.medicationStore) private var store
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize 
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRecording = false
    @State private var errorMessage: String?
    @State private var showingEditor = false

    let medicationID: UUID

    init(medicationID: UUID) {
        self.medicationID = medicationID
        _medications = Query(filter: #Predicate { $0.id == medicationID })
    }

    var body: some View {
        Group {
            if let model = medications.first {
                detailContent(for: model)
            } else {
                ContentUnavailableView(
                    "Medicamento no encontrado",
                    systemImage: "pills",
                    description: Text("Puede que se haya eliminado.")
                )
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Detail layout

    @ViewBuilder
    private func detailContent(for model: MedicationModel) -> some View {
        let medication = model.toDomain()
        let schedules = (model.schedules ?? []).compactMap { try? $0.toDomain() }
        let stockStatus = medication.stockStatus(for: schedules)
        let recentLogs: [IntakeLog] = (model.intakeLogs ?? [])
            .sorted { $0.scheduledAt > $1.scheduledAt }
            .prefix(10)
            .compactMap { try? $0.toDomain() }

        List {
            headerSection(medication: medication)

            Section {
                MedicationStatCards(
                    medication: medication,
                    schedules: schedules,
                    stockStatus: stockStatus
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            ForEach(schedules.indices, id: \.self) { i in
                let schedule = schedules[i]
                let times = schedule.displayDoseTimes()
                if !times.isEmpty {
                    Section {
                        ForEach(times.indices, id: \.self) { j in
                            MedicationScheduleRow(
                                time: times[j],
                                pillsPerDose: medication.pillsPerDose
                            )
                        }
                    } header: {
                        scheduleSectionHeader(for: schedule.frequency)
                    }
                }
            }

            if !recentLogs.isEmpty {
                Section("Historial de tomas") {
                    ForEach(recentLogs) { log in
                        IntakeLogRow(log: log)
                    }
                }
            }

            MedicationCalendarSection(medication: model)
        }
        .listStyle(.insetGrouped)
        .navigationTitle(medication.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Editar") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            MedicationEditorView(medication: medication, schedule: schedules.first)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            registerDoseButton(for: medication)
        }
    }

    // MARK: - Schedule section header

    /// Section title that mirrors the pauta kind: daily, the selected weekdays, or the
    /// dosing interval. Weekly pautas name their days here so the rows can list each time
    /// of day just once.
    private func scheduleSectionHeader(for frequency: DoseFrequency) -> Text {
        switch frequency {
        case .daily:
            return Text("Pauta diaria", comment: "Detail schedule section title — every day")
        case .weekdays(let days):
            let names = Self.weekdayNames(for: days)
            return Text(
                "Días: \(names)",
                comment: "Detail schedule section title — weekly. Placeholder is a list of weekday names"
            )
        case .everyNHours(let hours):
            return Text(
                "Cada \(hours) horas",
                comment: "Detail schedule section title — every N hours"
            )
        }
    }

    /// Selected weekdays as a short, comma-separated list in the user's locale order
    /// (honours `Calendar.firstWeekday`), reusing the system's localized day names.
    private static func weekdayNames(for days: [Weekday]) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        let first = Calendar.current.firstWeekday
        let selected = Set(days)
        let ordered = (0..<7).compactMap { offset in
            Weekday(rawValue: (first - 1 + offset) % 7 + 1)
        }
        let names = ordered
            .filter { selected.contains($0) }
            .compactMap { day -> String? in
                let index = day.rawValue - 1
                return symbols.indices.contains(index) ? symbols[index] : nil
            }
        return names.formatted(.list(type: .and))
    }

    // MARK: - Header section

    @ViewBuilder
    private func headerSection(medication: Medication) -> some View {
        Section {
            let layout: AnyLayout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                : AnyLayout(HStackLayout(spacing: 14))

            layout {
                MedicationFormIcon(form: medication.form)
                VStack(alignment: .leading, spacing: 3) {
                    Text(medication.name)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    if !medication.doseLabel.isEmpty {
                        Text(medication.doseLabel)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAction(named: "Editar") { showingEditor = true }
        }
    }

    // MARK: - Primary action button

    @ViewBuilder
    private func registerDoseButton(for medication: Medication) -> some View {
        Button("Registrar toma", systemImage: "checkmark.circle") {
            Task { await recordDose(for: medication) }
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .padding()
        .disabled(isRecording || store == nil)
        .accessibilityHint("Resta una pastilla del stock y registra la toma")
    }

    // MARK: - Dose recording

    private func recordDose(for medication: Medication) async {
        guard let store else { return }
        let remainingAfter = max(0, medication.currentStock - medication.pillsPerDose)
        let log = IntakeLog(
            id: UUID(),
            medicationID: medication.id,
            scheduledAt: .now,
            takenAt: .now,
            status: .taken,
            pillsTaken: medication.pillsPerDose
        )
        isRecording = true
        defer { isRecording = false }
        do {
            _ = try await store.recordIntake(log, decrementingStockBy: medication.pillsPerDose)
            let announcement = medication.doseRegisteredAnnouncement(remainingAfter: remainingAfter)
            AccessibilityNotification.Announcement(announcement).post()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    let controller = try? PersistenceController(inMemory: true)
    if let controller {
        let medicationID: UUID = {
            let context = ModelContext(controller.container)
            let med = MedicationModel()
            med.id = UUID(uuidString: "DEADBEEF-0000-0000-0000-000000000001") ?? UUID()
            med.name = "Metformina"
            med.doseLabel = "850 mg"
            med.formRaw = MedicationForm.pill.rawValue
            med.currentStock = 8
            med.lowStockThresholdDays = 7
            context.insert(med)
            let schedule = DoseScheduleModel()
            schedule.timesData = try? JSONEncoder().encode([DateComponents(hour: 8), DateComponents(hour: 21)])
            schedule.frequencyData = try? JSONEncoder().encode(DoseFrequency.daily)
            schedule.startDate = .now
            schedule.medication = med
            context.insert(schedule)
            try? context.save()
            return med.id
        }()

        NavigationStack {
            MedicationDetailView(medicationID: medicationID)
        }
        .modelContainer(controller.container)
        .environment(\.calendarSync, nil)
    }
}
