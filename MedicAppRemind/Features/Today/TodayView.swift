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

/// Owns the "current day" and keeps it on the wall clock, re-creating the day-scoped
/// content (and its `@Query`) whenever the day rolls over — when the app returns to the
/// foreground on a new day, or at midnight while it stays open.
struct TodayView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var currentDay = Calendar.current.startOfDay(for: .now)

    var body: some View {
        TodayContentView(day: currentDay)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active { syncToToday() }
            }
            .task(id: currentDay) { await scheduleMidnightRefresh() }
    }

    /// Advances `currentDay` if the wall clock has crossed into a new day.
    private func syncToToday() {
        let today = Calendar.current.startOfDay(for: .now)
        if today != currentDay { currentDay = today }
    }

    /// Sleeps until the next midnight, then advances the day. Restarted by `.task(id:)`
    /// each time `currentDay` changes, so it always targets the upcoming midnight.
    private func scheduleMidnightRefresh() async {
        let seconds = Calendar.current.secondsUntilNextDay(after: .now)
        try? await Task.sleep(for: .seconds(seconds))
        syncToToday()
    }
}

/// The day's dose schedule. Its `@Query` window is built from `day`, so SwiftUI rebuilds
/// it with fresh results whenever the parent advances to a new day.
private struct TodayContentView: View {
    @Environment(\.medicationStore) private var store
    @Environment(\.cloudSyncMonitor) private var cloudSyncMonitor
    @Query(sort: \MedicationModel.name) private var medications: [MedicationModel]
    @Query private var todayLogs: [IntakeLogModel]

    /// The day (as a reference-time key) whose completion was already celebrated,
    /// so the confetti fires at most once per calendar day even across relaunches.
    @AppStorage("celebratedDayKey") private var celebratedDayKey: Double = 0
    @State private var isCelebrating = false

    let day: Date

    init(day: Date) {
        self.day = day
        let bounds = Calendar.current.dayBounds(for: day)
        let start = bounds.start
        let end = bounds.end
        _todayLogs = Query(filter: #Predicate<IntakeLogModel> { log in
            log.scheduledAt >= start && log.scheduledAt < end
        })
    }

    private var slots: [DoseSlot] {
        DoseSlot.slots(from: medications, logs: todayLogs, on: day, calendar: .current)
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
                    Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    TodayProgressCard(slots: slots)
                        .padding(.horizontal)

                    if slots.isEmpty {
                        if medications.isEmpty && cloudSyncMonitor?.isSyncing == true {
                            CloudSyncingView()
                        } else {
                            ContentUnavailableView(
                                "Sin tomas hoy",
                                systemImage: "calendar.badge.checkmark",
                                description: Text("Añade medicamentos con pauta para ver tus tomas aquí.")
                            )
                        }
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
        .overlay {
            if isCelebrating {
                CelebrationOverlay { isCelebrating = false }
            }
        }
        .onChange(of: slots.isDayComplete) { _, complete in
            celebrateIfDayJustCompleted(complete)
        }
    }

    /// Fires the celebration when the day becomes complete, but only the first
    /// time it happens on a given day. Marking `celebratedDayKey` up front makes
    /// re-entrancy (query flicker, foregrounding) a no-op.
    private func celebrateIfDayJustCompleted(_ complete: Bool) {
        guard complete else { return }
        let key = day.timeIntervalSinceReferenceDate
        guard celebratedDayKey != key else { return }
        celebratedDayKey = key
        isCelebrating = true
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
