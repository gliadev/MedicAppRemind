//
//  DraftParserEnvironment.swift
//  MedicAppRemind
//
//  F10.S3 — Environment injection of the draft parser (same pattern as
//  calendarSync / cloudSyncMonitor). Features read the protocol, never
//  FoundationModels; previews and tests inject FakeDraftParser.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var draftParser: (any MedicationDraftParsing)? = nil
}
