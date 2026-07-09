//
//  ScanSymbology.swift
//  MedicAppRemind
//
//  FX.S3 — The 1D/2D symbologies the box scanner routes. A Domain-level mirror
//  of the AVFoundation metadata types, kept free of AVFoundation so the routing
//  stays pure and testable; the UIKit bridge maps `AVMetadataObject.ObjectType`
//  onto it (see `ScanSymbology+AVFoundation`).
//

enum ScanSymbology: Equatable {
    /// SEVeM DataMatrix — GS1 payload carrying CN + expiry + lot + serial.
    case dataMatrix
    /// Leaflet QR — a CIMA URL resolving to an nregistro.
    case qr
    /// OTC lineal EAN-13 — `847000` + CN.
    case ean13
}
