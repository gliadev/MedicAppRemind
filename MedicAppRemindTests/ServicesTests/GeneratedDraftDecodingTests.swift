//
//  GeneratedDraftDecodingTests.swift
//  MedicAppRemindTests
//
//  F10.S2 (rediseño String+JSON) — la salida del modelo es texto que DICE ser
//  JSON: fences, claves inventadas, enums fuera de catálogo y días en español
//  son casos reales capturados en el spike del 2026-11-16. La decodificación
//  es tolerante: un campo irreconocible se descarta, nunca rompe el draft.
//

import Testing
import Foundation
@testable import MedicAppRemind

@Suite("Model output → GeneratedMedicationDraft decoding")
struct GeneratedDraftDecodingTests {

    // MARK: Fixtures reales del spike (simulador, 2026-11-16)

    @Test("Spike fixture: ibuprofeno — fences fuera, everyNHours(8), weekdays inventados irrelevantes")
    func ibuprofenoFixture() throws {
        let output = """
        ```json
        {
          "name": "ibuprofeno",
          "doseLabel": "600",
          "pillsPerDose": 1,
          "currentStock": 30,
          "frequencyKind": "everyNHours",
          "everyNHours": 8,
          "weekdays": ["lunes", "martes", "miercoles", "jueves", "viernes", "sabado", "domingo"],
          "timesOfDay": []
        }
        ```
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        #expect(generated.name == "ibuprofeno")
        #expect(generated.doseLabel == "600")
        #expect(generated.pillsPerDose == 1.0)
        #expect(generated.currentStock == 30.0)

        let schedule = try #require(generated.schedule?.toDomainSchedule())
        // everyNHours manda; la lista de días inventada no contamina la pauta.
        #expect(schedule.kind == .everyNHours(8))
        #expect(schedule.timesOfDay == [])
    }

    @Test("Spike fixture: paracetamol — solo nombre, resto nil")
    func paracetamolFixture() throws {
        let output = """
        ```json
        { "name": "paracetamol" }
        ```
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        #expect(generated.name == "paracetamol")
        #expect(generated.doseLabel == nil)
        #expect(generated.pillsPerDose == nil)
        #expect(generated.currentStock == nil)
        #expect(generated.schedule == nil)
        #expect(!generated.isEmpty)
    }

    @Test("Spike fixture: Sintrom — días en español con acentos → Weekday de dominio")
    func sintromFixture() throws {
        let output = """
        {
          "name": "Sintrom",
          "doseLabel": "medio",
          "pillsPerDose": 1,
          "frequencyKind": "weekdays",
          "weekdays": ["lunes", "miércoles", "viernes"]
        }
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        let schedule = try #require(generated.schedule?.toDomainSchedule())
        #expect(schedule.kind == .weekdays([.monday, .wednesday, .friday]))
    }

    @Test("Spike fixture: lorazepam — frequencyKind 'weekly' no existe → sin pauta, resto intacto")
    func lorazepamUnknownKindFixture() throws {
        let output = """
        {
          "name": "Lorazepam",
          "doseLabel": "1 mg",
          "pillsPerDose": 1,
          "currentStock": 10,
          "frequencyKind": "weekly",
          "weekdays": ["lunes", "martes", "miércoles", "jueves", "viernes", "sabado", "domingo"]
        }
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        #expect(generated.name == "Lorazepam")
        #expect(generated.currentStock == 10.0)
        #expect(generated.schedule == nil)
    }

    @Test("Spike fixture: omeprazol — daily con hora exacta")
    func omeprazolFixture() throws {
        let output = """
        {
          "name": "omeprazol",
          "doseLabel": "20 mg",
          "pillsPerDose": 1,
          "currentStock": 28,
          "frequencyKind": "daily",
          "timesOfDay": [ { "hour": 8, "minute": 0 } ]
        }
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        let schedule = try #require(generated.schedule?.toDomainSchedule())
        #expect(schedule.kind == .daily)
        #expect(schedule.timesOfDay == [DraftTime(hour: 8, minute: 0)])
    }

    // MARK: Tolerancia y bordes

    @Test("Días en inglés (lo que piden las instructions) también mapean")
    func englishWeekdays() throws {
        let output = """
        { "name": "x", "frequencyKind": "weekdays", "weekdays": ["monday", "sunday"] }
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        let schedule = try #require(generated.schedule?.toDomainSchedule())
        #expect(schedule.kind == .weekdays([.monday, .sunday]))
    }

    @Test("Día irreconocible se descarta sin romper los demás")
    func unknownWeekdayDropped() throws {
        let output = """
        { "name": "x", "frequencyKind": "weekdays", "weekdays": ["lunes", "findesemana", "friday"] }
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        let schedule = try #require(generated.schedule?.toDomainSchedule())
        #expect(schedule.kind == .weekdays([.monday, .friday]))
    }

    @Test("form en texto mapea tolerante, incluido español")
    func formDecoding() throws {
        let english = try GeneratedMedicationDraft.decode(fromModelOutput: #"{ "name": "x", "form": "capsule" }"#)
        #expect(english.form == .capsule)
        let spanish = try GeneratedMedicationDraft.decode(fromModelOutput: #"{ "name": "x", "form": "comprimido" }"#)
        #expect(spanish.form == .tablet)
        let unknown = try GeneratedMedicationDraft.decode(fromModelOutput: #"{ "name": "x", "form": "supositorio galáctico" }"#)
        #expect(unknown.form == nil)
    }

    @Test("everyNHours sin valor de intervalo → sin pauta (nunca se inventa)")
    func intervalKindWithoutValue() throws {
        let output = #"{ "name": "x", "frequencyKind": "everyNHours" }"#
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        #expect(generated.schedule?.toDomainSchedule() == nil)
    }

    @Test("Respuesta sin JSON (negativa en prosa) → lanza")
    func proseOutputThrows() {
        #expect(throws: (any Error).self) {
            _ = try GeneratedMedicationDraft.decode(fromModelOutput: "I cannot help with that request.")
        }
    }

    @Test("Objeto vacío {} decodifica como draft vacío — el parser lo trata como fallo")
    func emptyObjectIsEmptyDraft() throws {
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: "{}")
        #expect(generated.isEmpty)
    }

    @Test("JSON con prosa alrededor: se extrae el objeto entre llaves")
    func jsonSurroundedByProse() throws {
        let output = """
        Here is the extracted data: { "name": "paracetamol" } Hope this helps!
        """
        let generated = try GeneratedMedicationDraft.decode(fromModelOutput: output)
        #expect(generated.name == "paracetamol")
    }
}
