//
//  ScanSymbology+AVFoundation.swift
//  MedicAppRemind
//
//  FX.S3 — Bridges the pure `ScanSymbology` (Domain) onto AVFoundation's metadata
//  types. Kept out of Domain so the routing layer never imports AVFoundation.
//

import AVFoundation

extension ScanSymbology {
    /// Maps an AVFoundation metadata type onto a routed symbology. Any type we
    /// don't scan for (or that Apple adds later) yields `nil` and is ignored.
    init?(metadataType: AVMetadataObject.ObjectType) {
        switch metadataType {
        case .dataMatrix: self = .dataMatrix
        case .qr: self = .qr
        case .ean13: self = .ean13
        default: return nil
        }
    }

    /// The metadata object types the scanner asks AVFoundation to detect.
    static let scannedMetadataTypes: [AVMetadataObject.ObjectType] = [.dataMatrix, .qr, .ean13]
}
