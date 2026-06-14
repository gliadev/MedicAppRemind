//
//  CloudSyncMonitor.swift
//  MedicAppRemind
//
//  F7.S2 — Observes NSPersistentCloudKitContainer events so the UI can show a
//  non-blocking "Sincronizando…" state and tell "no data" apart from "still
//  importing from iCloud". Events arrive over a block-based observer (no @objc,
//  no selector) bridged into an AsyncStream that carries only Sendable values —
//  the non-Sendable `Notification`/`Event` never crosses an actor boundary.
//

import CoreData
import SwiftUI

/// Tracks whether a CloudKit setup/import/export is currently in flight.
@MainActor
@Observable
final class CloudSyncMonitor {
    /// `true` while at least one CloudKit operation is running. The only observed
    /// property; the UI reads it to show a non-blocking sync indicator.
    private(set) var isSyncing = false

    /// Operations seen started (`endDate == nil`) but not yet finished. Counting by
    /// identifier tolerates overlapping import/export events: syncing stays `true`
    /// until every in-flight operation reports an end date.
    @ObservationIgnored private var inFlight: Set<UUID> = []
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var observer: (any NSObjectProtocol)?

    init() {}

    /// A Sendable snapshot of a container event — the only fields the UI needs,
    /// extracted on the posting thread so nothing non-Sendable is carried across.
    private struct Signal: Sendable {
        let identifier: UUID
        let finished: Bool
    }

    /// Begins observing container events. Idempotent — a second call is a no-op.
    func start() {
        guard task == nil else { return }
        let stream = AsyncStream<Signal> { continuation in
            observer = NotificationCenter.default.addObserver(
                forName: NSPersistentCloudKitContainer.eventChangedNotification,
                object: nil,
                queue: nil
            ) { notification in
                guard let event = notification.userInfo?[
                    NSPersistentCloudKitContainer.eventNotificationUserInfoKey
                ] as? NSPersistentCloudKitContainer.Event else { return }
                continuation.yield(Signal(
                    identifier: event.identifier,
                    finished: event.endDate != nil
                ))
            }
        }
        task = Task { [weak self] in
            for await signal in stream {
                self?.update(signal)
            }
        }
    }

    /// Stops observing and clears state. Safe to call more than once.
    func stop() {
        task?.cancel()
        task = nil
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
        inFlight.removeAll()
        isSyncing = false
    }

    private func update(_ signal: Signal) {
        if signal.finished {
            inFlight.remove(signal.identifier)
        } else {
            inFlight.insert(signal.identifier)
        }
        isSyncing = !inFlight.isEmpty
    }
}

extension EnvironmentValues {
    /// The app's CloudKit sync monitor, or `nil` before `RootView` wires it.
    @Entry var cloudSyncMonitor: CloudSyncMonitor? = nil
}
