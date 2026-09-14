//
//  AboutSettingsPage.swift
//  Visage
//

import SwiftUI

struct AboutSettingsPage: View {
    let environment: AppEnvironment

    /// Secret-tap state for revealing the Debug/Face Lab sidebar section —
    /// see `AppEnvironment.isDebugSectionRevealed`. A pause over a second
    /// resets the count, so this requires 5 *consecutive* taps.
    @State private var iconTapCount = 0
    @State private var lastTapDate: Date?
    private let requiredTapCount = 5
    private let tapResetInterval: TimeInterval = 1.0

    private var versionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "Version \(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: 14) {
            AppGlyph(size: 76)
                .padding(.top, 24)
                .contentShape(Rectangle())
                .onTapGesture(perform: handleIconTap)

            Text("Visage")
                .font(.title.weight(.bold))
                .foregroundStyle(SettingsMetrics.textPrimary)

            Text(versionString)
                .foregroundStyle(SettingsMetrics.textSecondary)

            Text("Face unlock for your Mac.\nYour face data never leaves this Mac.")
                .multilineTextAlignment(.center)
                .foregroundStyle(SettingsMetrics.textSecondary)

            Text("Made by cdwburhan")
                .font(.callout.weight(.semibold))
                .foregroundStyle(SettingsMetrics.textPrimary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    private func handleIconTap() {
        let now = Date()
        if let lastTapDate, now.timeIntervalSince(lastTapDate) > tapResetInterval {
            iconTapCount = 0
        }
        lastTapDate = now
        iconTapCount += 1
        guard iconTapCount >= requiredTapCount else { return }
        iconTapCount = 0
        environment.isDebugSectionRevealed = true
    }
}
