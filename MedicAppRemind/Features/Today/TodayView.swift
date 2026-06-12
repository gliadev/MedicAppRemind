//
//  TodayView.swift
//  MedicAppRemind
//
//  F6.S1 — Today's dose schedule: all doses for the current day, grouped by
//  time period, with a progress card. Built for WCAG 2.2 AA from the ground
//  up — every dose row is a single accessible action; section headers use
//  `.isHeader`; progress card summarises the day for VoiceOver.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.medicationStore) private var store
    @Query(sort: \MedicationModel.name) private var medications: [MedicationModel]
    @Query private var todayLogs: [IntakeLogModel]

    init() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start
        _todayLogs = Query(filter: #Predicate<IntakeLogModel> { log in
            log.scheduledAt >= start && log.scheduledAt < end
        })
    }

    private var slots: [DoseSlot] {
        DoseSlot.slots(from: medications, logs: todayLogs, on: .now, calendar: .current)
    }

    private var groupedSlots: [(DayPeriod, [DoseSlot])] {
        DayPeriod.allCases.compactMap { period in
            let periodSlots = slots.filter { $0.period == period }
            return periodSlots.isEmpty ? nil : (period, periodSlots)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(.now, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    TodayProgressCard(slots: slots)
                        .padding(.horizontal)

                    if slots.isEmpty {
                        ContentUnavailableView(
                            "Sin tomas hoy",
                            systemImage: "calendar.badge.checkmark",
                            description: Text("Añade medicamentos con pauta para ver tus tomas aquí.")
                        )
                    } else {
                        ForEach(groupedSlots, id: \.0) { period, periodSlots in
                            TodaySectionView(
                                period: period,
                                slots: periodSlots,
                                onToggle: toggleDose
                            )
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Hoy")
        }
    }

    // MARK: - Actions

    private func toggleDose(_ slot: DoseSlot) {
        guard let store, !slot.isTaken else { return }
        Task {
            let log = IntakeLog(
                id: slot.id,
                medicationID: slot.medicationID,
                scheduledAt: slot.scheduledAt,
                takenAt: .now,
                status: .taken,
                pillsTaken: slot.pillsPerDose
            )
            _ = try? await store.recordIntake(log, decrementingStockBy: slot.pillsPerDose)
        }
    }
}

#Preview {
    if let controller = try? PersistenceController(inMemory: true) {
        TodayView()
            .modelContainer(controller.container)
    }
}
