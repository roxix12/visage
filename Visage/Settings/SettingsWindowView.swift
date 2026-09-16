//
//  SettingsWindowView.swift
//  Visage
//
//  Root layout: a sidebar of panes (icon tiles, grouped under section
//  headers, with the setup status and credit at the bottom) beside an inset
//  rounded detail card holding the selected pane's header and scrolling page.
//

import SwiftUI

/// A closure `onPreferenceChange` can actually consume — that API requires
/// `Value: Equatable`, which a bare closure can never be. Equality is by
/// identity (a fresh `id` per instance), so this is deliberately never
/// equal to a previous instance.
struct HeaderAction: Equatable {
    private let id = UUID()
    let perform: () -> Void

    static func == (lhs: HeaderAction, rhs: HeaderAction) -> Bool { lhs.id == rhs.id }
}

/// Lets one page (today, only Camera's "Refresh camera list") publish a
/// trailing action into the shared header without the header needing
/// to know that page's state. Switching away resolves back to `defaultValue`.
struct HeaderTrailingActionKey: PreferenceKey {
    static var defaultValue: HeaderAction? { nil }
    static func reduce(value: inout HeaderAction?, nextValue: () -> HeaderAction?) {
        value = nextValue() ?? value
    }
}

struct SettingsWindowView: View {
    let environment: AppEnvironment
    @State private var selection: SettingsTab = .overview
    @State private var headerTrailingAction: HeaderAction?
    @Environment(\.dismissWindow) private var dismissWindow

    /// Defense-in-depth, not the primary gate: Settings is `.suppressed` at
    /// launch and `AppDelegate.revealSettingsWindow()` refuses to open it
    /// while onboarding is incomplete. A real user should never hit this
    /// branch, only a blank frame before `dismissWindow` closes it.
    var body: some View {
        if VisageSettings.shared.hasCompletedOnboarding {
            settingsContent
        } else {
            Color.clear
                .onAppear { dismissWindow(id: "settings") }
        }
    }

    private var settingsContent: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: SettingsMetrics.sidebarWidth)
            detail
                .background(
                    RoundedRectangle(cornerRadius: SettingsMetrics.detailCornerRadius, style: .continuous)
                        .fill(Color.primary.opacity(0.035))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: SettingsMetrics.detailCornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.07))
                )
                .padding(10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // No `.clipShape`, manual stroke, or `.shadow` on the outer window —
        // deliberately: the window keeps its native background (see
        // WindowConfiguringView), so AppKit masks it to the real macOS
        // corner and draws its own edge highlight and shadow for free.
        .background(VisualEffectView().ignoresSafeArea())
        .ignoresSafeArea()
        .background(WindowConfigurator())
        .onPreferenceChange(HeaderTrailingActionKey.self) { headerTrailingAction = $0 }
        // `Window` is a singleton scene — closing it only orders the
        // NSWindow out, keeping `@State` alive, so without this `selection`
        // would remember the last pane instead of resetting to Overview.
        .onDisappear { selection = .overview }
    }

    // MARK: - Sidebar

    /// Top padding clears the window's real traffic lights, which AppKit
    /// draws over the sidebar's leading corner (see WindowConfiguringView).
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            let sections = SettingsTab.sections(includingDebug: environment.isDebugSectionRevealed)
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                if let title = section.title {
                    sectionHeader(title)
                }
                ForEach(section.tabs) { tab in
                    item(tab)
                }
            }

            Spacer(minLength: 12)

            statusPill

            Text("Made by cdwburhan")
                .font(.caption2.weight(.medium))
                .foregroundStyle(.tertiary)
                .padding(.leading, 6)
                .padding(.top, 6)
        }
        .padding(.horizontal, 12)
        .padding(.top, SettingsMetrics.headerHeight)
        .padding(.bottom, 14)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.callout.weight(.medium))
            .foregroundStyle(.secondary)
            .padding(.leading, 10)
            .padding(.top, 18)
            .padding(.bottom, 4)
    }

    private func item(_ tab: SettingsTab) -> some View {
        let isSelected = selection == tab
        return Button {
            selection = tab
        } label: {
            HStack(spacing: 10) {
                IconTile(symbol: tab.symbol, color: tab.color)
                Text(tab.title)
                    .foregroundStyle(SettingsMetrics.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                isSelected ? Color.primary.opacity(0.1) : .clear,
                in: RoundedRectangle(cornerRadius: 9, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Setup at a look: Face Unlock needs both the switch on and a stored password.
    private var statusPill: some View {
        let hasPassword = environment.pocController.hasStoredPassword
        let isReady = environment.faceUnlockCoordinator.isEnabled && hasPassword
        return HStack(spacing: 8) {
            Image(systemName: isReady ? "checkmark.shield.fill" : "exclamationmark.shield")
            Text(isReady ? "Face Unlock ready" : (hasPassword ? "Face Unlock off" : "Not set up"))
        }
        .font(.callout.weight(.medium))
        .foregroundStyle(SettingsMetrics.textPrimary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Detail

    private var detail: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView(.vertical) {
                pageBody
                    .padding(.horizontal, SettingsMetrics.contentHorizontalPadding)
                    .padding(.bottom, 24)
                    // Without an explicit top alignment the scroll view
                    // centers short pages vertically.
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            IconTile(symbol: selection.symbol, color: selection.color)
            Text(selection.title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(SettingsMetrics.textPrimary)

            Spacer()

            if let headerTrailingAction {
                Button(action: headerTrailingAction.perform) {
                    Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                        .font(.system(size: 13))
                        .foregroundStyle(SettingsMetrics.textPrimary)
                        .frame(width: SettingsMetrics.headerButtonHeight, height: SettingsMetrics.headerButtonHeight)
                        .background(Circle().fill(SettingsMetrics.rowColor))
                        .overlay(
                            Circle()
                                .strokeBorder(SettingsMetrics.rowBorder, lineWidth: SettingsMetrics.rowBorderWidth)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Refresh camera list")
            }

            SessionLockButton(pocController: environment.pocController)
        }
        .padding(.horizontal, SettingsMetrics.contentHorizontalPadding)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private var pageBody: some View {
        VStack(alignment: .leading, spacing: SettingsMetrics.rowSpacing) {
            switch selection {
            case .overview:
                OverviewSettingsPage(environment: environment) { selection = $0 }
            case .general:
                GeneralSettingsPage(coordinator: environment.faceUnlockCoordinator)
            case .yourFace:
                YourFaceSettingsPage(environment: environment)
            case .password:
                PasswordSettingsPage(pocController: environment.pocController)
            case .camera:
                CameraSettingsPage(pocController: environment.pocController)
            case .recognition:
                RecognitionSettingsPage(
                    coordinator: environment.faceUnlockCoordinator,
                    pocController: environment.pocController
                )
            case .privacy:
                PrivacySettingsPage(pocController: environment.pocController)
            case .community:
                CommunitySettingsPage()
            case .about:
                AboutSettingsPage(environment: environment)
            case .debugFaceLab:
                FaceLabView(controller: environment.faceLabController)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
