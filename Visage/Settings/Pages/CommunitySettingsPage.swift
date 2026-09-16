//
//  CommunitySettingsPage.swift
//  Visage
//
//  The Discord invite. The logo is Discord's own artwork, shown unmodified.
//

import SwiftUI
import AppKit

struct CommunitySettingsPage: View {
    static let inviteURL = URL(string: "https://discord.gg/qzyHE752")!

    @State private var didCopy = false

    var body: some View {
        VStack(spacing: 14) {
            Image("DiscordIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .padding(.top, 20)

            Text("Join the Visage community")
                .font(.title2.weight(.bold))
                .foregroundStyle(SettingsMetrics.textPrimary)

            Text("Ask questions, report a face that won't match, suggest features\nand hear about new builds first.")
                .multilineTextAlignment(.center)
                .foregroundStyle(SettingsMetrics.textSecondary)

            SettingsPrimaryButton(title: "Open Discord") {
                NSWorkspace.shared.open(Self.inviteURL)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 8)

        SettingsGroup {
            SettingsRowContent(title: "Invite link", subtitle: Self.inviteURL.absoluteString) {
                SettingsPrimaryButton(title: didCopy ? "Copied" : "Copy", compact: true) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(Self.inviteURL.absoluteString, forType: .string)
                    didCopy = true
                }
            }
            SettingsGroupDivider()
            SettingsActionRowContent(title: "Report a problem", buttonTitle: "Open") {
                NSWorkspace.shared.open(Self.inviteURL)
            }
        }

        SettingsCaption(text: "Opening Discord leaves Visage and uses your browser or the Discord app. A free Discord account is needed to join.")
    }
}
