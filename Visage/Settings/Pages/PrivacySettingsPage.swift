//
//  PrivacySettingsPage.swift
//  Visage
//
//  What Visage keeps, where, and how it's protected.
//

import SwiftUI

struct PrivacySettingsPage: View {
    @Bindable var pocController: POCController

    var body: some View {
        Card(padding: 0) {
            VStack(spacing: 0) {
                StatusRow(symbol: "cpu", color: .blue, title: "Processed on this Mac",
                          detail: "Detection, recognition and liveness run locally with Vision and Core ML.")
                RowDivider()
                StatusRow(symbol: "eye.slash.fill", color: .indigo, title: "No photos saved",
                          detail: "Camera frames stay in memory; only 512-number face embeddings are kept.")
                RowDivider()
                StatusRow(symbol: "key.fill", color: .orange, title: "Encrypted on disk",
                          detail: "Face data and your password use AES-GCM with a Keychain key behind Touch ID.")
                RowDivider()
                StatusRow(symbol: "wifi.slash", color: .gray, title: "No network",
                          detail: "No cloud, no accounts, no telemetry.")
                RowDivider()
                StatusRow(
                    symbol: "lock.fill", color: Color(white: 0.22), title: "Mac password",
                    detail: "Typed on the lock screen only after your face and liveness checks pass.",
                    badge: pocController.hasStoredPassword ? Badge("Stored", .orange) : Badge("Not stored", .secondary)
                )
            }
        }
        .onAppear { pocController.refreshCredentialStatus() }

        SettingsCaption(text: "A regular webcam is not the 3D TrueDepth camera behind Apple's Face ID. Visage is a convenience, not a security upgrade.")
    }
}
