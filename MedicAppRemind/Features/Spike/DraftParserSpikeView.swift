//
//  DraftParserSpikeView.swift
//  MedicAppRemind
//
//  F10.S2 — PANTALLA TEMPORAL DE SPIKE. Eliminar (carpeta Features/Spike y su
//  Tab en RootView) en cuanto el spike quede anotado en el ADR.
//  Valida el parser real en device vía TestFlight (sin cable): lanza la matriz
//  de frases ES contra el modelo y muestra el resultado y la latencia en
//  pantalla, con ShareLink para exportar. Strings sin localizar a propósito:
//  pantalla interna desechable, nunca llega a la release final.
//

import SwiftUI

@MainActor
struct DraftParserSpikeView: View {

    /// Matriz del spike: completa, parcial, compleja, normal y una con riesgo
    /// de guardrails (psicofármaco). La no-medicación se prueba en F10.S4.
    private static let phrases = [
        "Ibuprofeno 600, una pastilla cada 8 horas, me quedan 30",
        "paracetamol y ya está",
        "Medio comprimido de Sintrom en ayunas los lunes, miércoles y viernes",
        "Omeprazol 20 mg, una cápsula antes de desayunar, tengo 28",
        "Lorazepam 1 mg, una pastilla antes de dormir, me quedan 10"
    ]

    private let parser = FoundationModelsDraftParser()

    @State private var results: [String] = []
    @State private var runID = 0
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            List {
                Section("Estado") {
                    LabeledContent("Modelo disponible", value: parser.isAvailable ? "Sí" : "No")
                }
                Section("Resultados") {
                    if results.isEmpty {
                        Text(isRunning ? "Ejecutando…" : "Pulsa Ejecutar para lanzar las 5 frases.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                        Text(result)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
            }
            .navigationTitle("Spike F10.S2")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Ejecutar", systemImage: "play.fill") { runID += 1 }
                        .disabled(isRunning)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: results.joined(separator: "\n\n"))
                        .disabled(results.isEmpty)
                }
            }
            .task(id: runID) { await runSpike() }
        }
    }

    private func runSpike() async {
        guard runID > 0, !isRunning else { return }
        isRunning = true
        defer { isRunning = false }
        results = []

        let clock = ContinuousClock()
        for phrase in Self.phrases {
            let start = clock.now
            var line = "» \(phrase)\n"
            do {
                let draft = try await parser.parseDraft(from: phrase)
                line += describe(draft)
            } catch {
                line += "✗ ERROR couldNotParse"
            }
            let elapsed = start.duration(to: clock.now)
            line += "\n⏱ \(elapsed.formatted(.units(allowed: [.seconds, .milliseconds], width: .narrow)))"
            results.append(line)
        }
    }

    private func describe(_ draft: MedicationDraft) -> String {
        var lines: [String] = []
        lines.append("name: \(draft.name ?? "—")")
        lines.append("doseLabel: \(draft.doseLabel ?? "—")")
        lines.append("pillsPerDose: \(draft.pillsPerDose.map { $0.formatted() } ?? "—")")
        lines.append("form: \(draft.form.map { $0.rawValue } ?? "—")")
        lines.append("stock: \(draft.currentStock.map { $0.formatted() } ?? "—")")
        lines.append("schedule: \(draft.schedule.map(describe) ?? "—")")
        return lines.joined(separator: "\n")
    }

    private func describe(_ schedule: DraftSchedule) -> String {
        let times = (schedule.timesOfDay ?? []).map { time in
            let minute = time.minute < 10 ? "0\(time.minute)" : "\(time.minute)"
            return "\(time.hour):\(minute)"
        }
        let kind: String
        switch schedule.kind {
        case .daily:
            kind = "daily"
        case .everyNHours(let hours):
            kind = "cada \(hours) h"
        case .weekdays(let days):
            kind = "weekdays \(days.map { String(describing: $0) }.joined(separator: ","))"
        }
        return kind + (times.isEmpty ? "" : " @ " + times.joined(separator: " · "))
    }
}
