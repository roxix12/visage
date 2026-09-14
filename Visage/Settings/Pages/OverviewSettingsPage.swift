//
//  OverviewSettingsPage.swift
//  Visage
//
//  The first pane: whether Face Unlock is ready, and the state of each
//  piece it depends on, with shortcuts to the panes that change them.
//

import SwiftUI

struct OverviewSettingsPage: View {
    let environment: AppEnvironment
    /// Moves the sidebar selection, so this page can hand off to the pane that owns a setting.
    let navigate: (SettingsTab) -> Void
    @Bindable private var settings = VisageSettings.shared

    private var pocController: POCController { environment.pocController }
    private var coordinator: FaceUnlockCoordinator { environment.faceUnlockCoordinator }
    private var isReady: Bool { coordinator.isEnabled && pocController.hasStoredPassword }

    var body: some View {
        Card(padding: 24) {
            HStack(alignment: .center, spacing: 22) {
                AppGlyph(size: 64)
                VStack(alignment: .leading, spacing: 8) {
                    Text(isReady ? "Visage is ready" : "Set up Visage")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(SettingsMetrics.textPrimary)
                    Text(isReady
                         ? "Your Mac unlocks when it recognizes your face. Everything stays on this Mac."
                         : "Store your Mac password and turn on Face Unlock to open your Mac with your face.")
                        .foregroundStyle(SettingsMetrics.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        primaryAction
                        Button("Your Face") { navigate(.yourFace) }
                            .controlSize(.large)
                    }
                    .padding(.top, 6)
                }
                Spacer(minLength: 0)
            }
        }
        .onAppear { pocController.refreshCredentialStatus() }

        SettingsSectionTitle(text: "Status")
            .padding(.bottom, -8)

        Card(padding: 0) {
            VStack(spacing: 0) {
                StatusRow(
                    symbol: "faceid", color: .blue, title: "Face Unlock", detail: triggerDetail,
                    badge: coordinator.isEnabled ? Badge("On", .green) : Badge("Off", .secondary)
                )
                RowDivider()
                StatusRow(
                    symbol: "lock.fill", color: Color(white: 0.22), title: "Mac password",
                    detail: pocController.hasStoredPassword ? "Encrypted on this Mac behind Touch ID" : "Needed to type on the lock screen",
                    badge: pocController.hasStoredPassword ? Badge("Stored", .green) : Badge("Not set", .orange)
                )
                RowDivider()
                StatusRow(
                    symbol: pocController.isSessionUnlocked ? "lock.open.fill" : "lock.fill", color: .green, title: "Session",
                    detail: pocController.isSessionUnlocked ? "Face data and settings are open" : "Touch ID opens face data and settings",
                    badge: pocController.isSessionUnlocked ? Badge("Unlocked", .green) : Badge("Locked", .secondary)
                )
                RowDivider()
                StatusRow(
                    symbol: "checkmark.seal.fill", color: .purple, title: "Liveness",
                    detail: settings.livenessChecksEnabled ? "\(settings.livenessMode.title) checks for a live face" : "Photos are not screened",
                    badge: settings.livenessChecksEnabled ? Badge("On", .green) : Badge("Off", .orange)
                )
                RowDivider()
                StatusRow(symbol: "cpu", color: .pink, title: "Recognition model", detail: "ArcFace · runs on this Mac")
            }
        }

        SettingsCaption(text: "A regular webcam has no depth sensor, so a photo or video of you may unlock this Mac. Touch ID and your password keep working.")
    }

    @ViewBuilder
    private var primaryAction: some View {
        if !pocController.hasStoredPassword {
            Button("Set Password") { OnboardingController.startPasswordOnly() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        } else if !coordinator.isEnabled {
            Button("Turn On Face Unlock") { coordinator.isEnabled = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        } else {
            Button("Recognition") { navigate(.recognition) }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
    }

    private var triggerDetail: String {
        let triggers = UnlockTrigger.allCases
            .filter { settings.unlockTriggers.contains($0) }
            .map { $0.title.lowercased() }
        return triggers.isEmpty ? "No triggers selected" : "Scans " + triggers.joined(separator: ", ")
    }
}
