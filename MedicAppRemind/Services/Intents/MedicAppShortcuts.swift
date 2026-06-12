//
//  MedicAppShortcuts.swift
//  MedicAppRemind
//
//  F5.S3 — Predefined App Shortcuts for Siri and the Shortcuts app. Declarative
//  plumbing: it binds the two voice-friendly intents to their invocation phrases.
//  Phrases use `\(.applicationName)` (display name "MediRemind"), never the bundle
//  ID, and are written in the app's default language (ES); Xcode extracts them into
//  `AppShortcuts.xcstrings` on build for EN translation. iOS discovers this provider
//  automatically — no registration needed.
//
//  `ScheduleReminderIntent` is intentionally not exposed here: it needs an explicit
//  `time: Date`, which doesn't map to a fixed-phrase shortcut; it stays available
//  via the Shortcuts editor.
//

import AppIntents

struct MedicAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogDoseIntent(),
            phrases: [
                "Registra una toma en \(.applicationName)",
                "He tomado mi medicación con \(.applicationName)"
            ],
            shortTitle: "Registrar toma",
            systemImageName: "pills.fill"
        )
        AppShortcut(
            intent: QueryRemainingIntent(),
            phrases: [
                "Cuántas pastillas me quedan en \(.applicationName)",
                "Consulta mi stock con \(.applicationName)"
            ],
            shortTitle: "Consultar restante",
            systemImageName: "chart.bar.fill"
        )
    }
}
