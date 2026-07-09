//
//  MedicationEditorView.swift
//  MedicAppRemind
//
//  F6.S3 — WCAG 2.2 AA-audited medication editor. Layout follows Screen 03 of
//  docs/design-mockups. Accessibility guarantees:
//  • Every field carries a visible label and an explicit .accessibilityLabel.
//  • Validation errors surface as visible Text AND move VoiceOver focus to the
//    first invalid field via @AccessibilityFocusState.
//  • Numeric fields use .keyboardType(.decimalPad) and .submitLabel.
//

import SwiftUI

struct MedicationEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.medicationStore) private var store

    // MARK: - Form state

    @State private var name: String
    @State private var doseLabel: String
    @State private var pillsPerDoseText: String
    @State private var currentStockText: String
    @State private var times: [DateComponents]
    @State private var notificationsEnabled = true
    @State private var showingTimePicker = false
    @State private var showingScanner = false
    @State private var pickerTime: Date

    // Pauta (AX-04): editing mode + the values each mode needs.
    @State private var kind: ScheduleKind
    @State private var selectedWeekdays: Set<Weekday>
    @State private var intervalHours: Int
    @State private var startTime: Date

    // MARK: - Validation + save

    @State private var validationErrors: Set<ValidationError> = []
    @State private var isSaving = false

    // MARK: - Accessibility focus

    @AccessibilityFocusState private var focusedField: EditorField?

    // MARK: - Source data

    private let existingMedication: Medication?
    private let existingSchedule: DoseSchedule?
    private var isNew: Bool { existingMedication == nil }

    // MARK: - Init

    init(medication: Medication? = nil, schedule: DoseSchedule? = nil) {
        existingMedication = medication
        existingSchedule = schedule

        _name = State(initialValue: medication?.name ?? "")
        _doseLabel = State(initialValue: medication?.doseLabel ?? "")
        _pillsPerDoseText = State(initialValue: medication.map {
            $0.pillsPerDose.formatted(.number.precision(.fractionLength(0...2)))
        } ?? "1")
        _currentStockText = State(initialValue: medication.map {
            $0.currentStock.formatted(.number.precision(.fractionLength(0...2)))
        } ?? "0")
        _times = State(initialValue: schedule?.times ?? [])
        _pickerTime = State(initialValue: {
            Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
        }())

        let frequency = schedule?.frequency
        _kind = State(initialValue: frequency.map(ScheduleKind.init) ?? .daily)
        _selectedWeekdays = State(initialValue: frequency?.selectedWeekdays ?? [])
        _intervalHours = State(initialValue: frequency?.intervalHours ?? DoseFrequency.defaultIntervalHours)
        _startTime = State(initialValue: {
            let fallback = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
            return schedule?.startDate ?? fallback
        }())
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameAndDoseSection()
                quantitySection()
                scheduleSection()
                notificationsSection()
            }
            .navigationTitle(isNew ? "Nuevo medicamento" : "Editar medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Guardar") { Task { await save() } }
                        .bold()
                        .disabled(isSaving)
                        .accessibilityHint("Guarda los datos de este medicamento")
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet()
            }
            .sheet(isPresented: $showingScanner) {
                MedicationScannerScreen(onResult: applyScan)
            }
        }
    }

    /// Prefills the name/dose fields from a CIMA lookup, leaving anything it didn't
    /// carry untouched so the user never loses what they already typed.
    private func applyScan(_ suggestion: MedicationLookupSuggestion) {
        if !suggestion.nombre.isEmpty { self.name = suggestion.nombre }
        if let dosis = suggestion.dosis, !dosis.isEmpty { self.doseLabel = dosis }
    }

    // MARK: - Sections

    @ViewBuilder
    private func nameAndDoseSection() -> some View {
        Section("Nombre y dosis") {
            Button("Escanear caja", systemImage: "camera.viewfinder") {
                showingScanner = true
            }
            .accessibilityHint("Usa la cámara para rellenar el nombre y la dosis desde la caja")

            VStack(alignment: .leading, spacing: 4) {
                Text("Nombre del medicamento")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Nombre", text: $name)
                    .submitLabel(.next)
                    .accessibilityLabel("Nombre del medicamento")
                    .accessibilityFocused($focusedField, equals: .name)
                if validationErrors.contains(.emptyName) {
                    validationText(for: .emptyName)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Dosis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Ej. 850 mg", text: $doseLabel)
                    .submitLabel(.done)
                    .accessibilityLabel("Etiqueta de dosis")
                    .accessibilityHint("Descripción de la dosis, por ejemplo 850 mg o 20 mcg")
            }
        }
    }

    @ViewBuilder
    private func quantitySection() -> some View {
        Section("Cantidad por toma") {
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("Pastillas por toma") {
                    TextField("1", text: $pillsPerDoseText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60)
                        .accessibilityLabel("Pastillas por toma")
                        .accessibilityFocused($focusedField, equals: .pillsPerDose)
                }
                if validationErrors.contains(.nonPositivePillsPerDose) {
                    validationText(for: .nonPositivePillsPerDose)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                LabeledContent("Stock actual") {
                    TextField("0", text: $currentStockText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(minWidth: 60)
                        .accessibilityLabel("Stock actual en pastillas")
                        .accessibilityHint("Número de pastillas que tienes en casa ahora mismo")
                        .accessibilityFocused($focusedField, equals: .stock)
                }
                if validationErrors.contains(.negativeStock) {
                    validationText(for: .negativeStock)
                }
            }
        }
    }

    @ViewBuilder
    private func scheduleSection() -> some View {
        Section("Horario de tomas") {
            Picker("Tipo de pauta", selection: $kind) {
                Text("Cada día").tag(ScheduleKind.daily)
                Text("Días concretos").tag(ScheduleKind.weekdays)
                Text("Cada X horas").tag(ScheduleKind.everyNHours)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Tipo de pauta")

            if validationErrors.contains(.emptySchedule) {
                validationText(for: .emptySchedule)
                    .accessibilityFocused($focusedField, equals: .schedule)
            }

            switch kind {
            case .daily:
                timesEditor()
            case .weekdays:
                weekdaySelector()
                timesEditor()
            case .everyNHours:
                intervalEditor()
            }
        }
    }

    @ViewBuilder
    private func timesEditor() -> some View {
        ForEach(times.indices, id: \.self) { i in
            timeRow(at: i)
        }

        Button("Añadir hora", systemImage: "plus.circle") {
            showingTimePicker = true
        }
        .accessibilityHint("Añade una hora de toma a la pauta")
    }

    @ViewBuilder
    private func weekdaySelector() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Días de la semana")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Self.orderedWeekdays, id: \.self) { day in
                    weekdayChip(day)
                }
            }
        }
    }

    @ViewBuilder
    private func weekdayChip(_ day: Weekday) -> some View {
        let isOn = selectedWeekdays.contains(day)
        Button {
            if isOn { selectedWeekdays.remove(day) } else { selectedWeekdays.insert(day) }
        } label: {
            Text(Self.veryShortSymbol(for: day))
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isOn ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.quaternary))
                }
                .overlay(alignment: .topTrailing) {
                    if isOn {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(2)
                            .accessibilityHidden(true)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Self.fullSymbol(for: day))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityHint("Toca para activar o desactivar este día")
    }

    @ViewBuilder
    private func intervalEditor() -> some View {
        Picker("Cada cuántas horas", selection: $intervalHours) {
            ForEach(DoseFrequency.intervalPresets, id: \.self) { hours in
                Text("Cada \(hours) horas").tag(hours)
            }
        }

        DatePicker("Primera toma", selection: $startTime, displayedComponents: .hourAndMinute)
            .accessibilityLabel("Hora de la primera toma")

        if let preview = intervalFireTimesText {
            LabeledContent("Avisos") { Text(preview) }
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private func timeRow(at index: Int) -> some View {
        let comps = times[index]
        let label = formattedTime(hour: comps.hour ?? 0, minute: comps.minute ?? 0)
        HStack {
            Text(label)
                .font(.body.monospacedDigit())
            Spacer()
            Button("Quitar", systemImage: "xmark.circle.fill") {
                times.remove(at: index)
            }
            .foregroundStyle(.secondary)
            .labelStyle(.iconOnly)
            .accessibilityLabel("Quitar hora \(label)")
        }
    }

    @ViewBuilder
    private func notificationsSection() -> some View {
        Section {
            Toggle(isOn: $notificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recordatorios")
                    Text("Avisar a la hora de cada toma")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityLabel("Recordatorios activos")
            .accessibilityHint("Activa o desactiva las notificaciones de este medicamento")
        }
    }

    // MARK: - Time picker sheet

    @ViewBuilder
    private func timePickerSheet() -> some View {
        NavigationStack {
            DatePicker(
                "Hora de toma",
                selection: $pickerTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .accessibilityLabel("Selecciona la hora de la toma")
            .padding()
            .navigationTitle("Añadir hora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") { showingTimePicker = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Añadir") {
                        let comps = Calendar.current.dateComponents([.hour, .minute], from: pickerTime)
                        if !times.contains(comps) { times.append(comps) }
                        showingTimePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Validation text helper

    @ViewBuilder
    private func validationText(for error: ValidationError) -> some View {
        Text(error.errorDescription ?? "")
            .font(.caption)
            .foregroundStyle(.red)
            .accessibilityLabel("Error: \(error.errorDescription ?? "")")
    }

    // MARK: - Helpers

    private func formattedTime(hour: Int, minute: Int) -> String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let date = Calendar.current.date(from: comps) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }

    /// Weekdays in the user's locale order (honours `Calendar.firstWeekday`).
    private static let orderedWeekdays: [Weekday] = {
        let first = Calendar.current.firstWeekday
        return (0..<7).compactMap { offset in
            Weekday(rawValue: (first - 1 + offset) % 7 + 1)
        }
    }()

    private static func veryShortSymbol(for day: Weekday) -> String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let index = day.rawValue - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    private static func fullSymbol(for day: Weekday) -> String {
        let symbols = Calendar.current.weekdaySymbols
        let index = day.rawValue - 1
        return symbols.indices.contains(index) ? symbols[index] : ""
    }

    /// Preview of the fire times for the current interval pauta (e.g. "8:00 · 16:00 · 0:00"),
    /// reusing the Domain's trigger expansion so the editor never re-derives the rhythm.
    private var intervalFireTimesText: String? {
        let schedule = DoseSchedule(
            times: [],
            frequency: .everyNHours(intervalHours),
            startDate: startTime,
            endDate: nil
        )
        let labels = schedule.doseTriggerComponents().map {
            formattedTime(hour: $0.hour ?? 0, minute: $0.minute ?? 0)
        }
        return labels.isEmpty ? nil : labels.joined(separator: " · ")
    }

    /// The schedule start date. For `.everyNHours` the time of day comes from the
    /// "primera toma" picker (it anchors the interval rhythm); otherwise the existing
    /// start date is kept, or now for a new medication.
    private func resolvedStartDate() -> Date {
        let base = existingSchedule?.startDate ?? .now
        guard kind == .everyNHours else { return base }
        let calendar = Calendar.current
        var merged = calendar.dateComponents([.year, .month, .day], from: base)
        let time = calendar.dateComponents([.hour, .minute], from: startTime)
        merged.hour = time.hour
        merged.minute = time.minute
        return calendar.date(from: merged) ?? base
    }

    private func collectValidationErrors(medication: Medication, schedule: DoseSchedule) -> Set<ValidationError> {
        var errors: Set<ValidationError> = []
        if !medication.name.contains(where: { !$0.isWhitespace }) { errors.insert(.emptyName) }
        if medication.currentStock < 0                             { errors.insert(.negativeStock) }
        if medication.pillsPerDose <= 0                           { errors.insert(.nonPositivePillsPerDose) }
        do { try schedule.validated() } catch let e as ValidationError { errors.insert(e) } catch { }
        return errors
    }

    // MARK: - Save

    private func save() async {
        guard let store else { return }

        let pillsPerDose = Double(pillsPerDoseText.replacing(",", with: ".")) ?? 0
        let currentStock = Double(currentStockText.replacing(",", with: ".")) ?? 0

        let medication = Medication(
            id: existingMedication?.id ?? UUID(),
            name: name,
            notes: existingMedication?.notes ?? "",
            form: existingMedication?.form ?? .pill,
            doseLabel: doseLabel,
            pillsPerDose: pillsPerDose,
            currentStock: currentStock,
            lowStockThresholdDays: existingMedication?.lowStockThresholdDays ?? 7,
            createdAt: existingMedication?.createdAt ?? .now,
            updatedAt: .now
        )

        let frequency = DoseFrequency(
            kind: kind,
            weekdays: selectedWeekdays,
            intervalHours: intervalHours
        )
        let schedule = DoseSchedule(
            times: times,
            frequency: frequency,
            startDate: resolvedStartDate(),
            endDate: existingSchedule?.endDate
        )

        let errors = collectValidationErrors(medication: medication, schedule: schedule)
        guard errors.isEmpty else {
            validationErrors = errors
            focusedField = EditorField.firstInvalidField(for: errors)
            return
        }

        isSaving = true
        defer { isSaving = false }
        do {
            try await store.upsert(medication, schedule: schedule)
            // Schedule/stock may have changed → reprogram reminders (same pattern as
            // RootView bootstrap and ScheduleReminderIntent). refreshAllReminders is
            // idempotent: it clears all pending requests and recomputes from scratch.
            let plans = (try? await store.fetchPlans()) ?? []
            await NotificationService().refreshAllReminders(for: plans)
            dismiss()
        } catch {
            // Store-level error; validation path is covered above.
        }
    }
}

// MARK: - Preview

#Preview("Nuevo") {
    MedicationEditorView()
}

#Preview("Editar") {
    let med = Medication(
        id: UUID(),
        name: "Metformina",
        notes: "",
        form: .pill,
        doseLabel: "850 mg",
        pillsPerDose: 1,
        currentStock: 8,
        lowStockThresholdDays: 7,
        createdAt: .now,
        updatedAt: .now
    )
    let schedule = DoseSchedule(
        times: [DateComponents(hour: 8), DateComponents(hour: 21)],
        frequency: .daily,
        startDate: .now,
        endDate: nil
    )
    MedicationEditorView(medication: med, schedule: schedule)
}
