//
//  SettingsMetrics.swift
//  Visage
//
//  Design tokens for the Settings window — one file to tune sizing/color
//  in rather than scattered literals.
//

import SwiftUI

enum SettingsMetrics {
    static let windowSize = CGSize(width: 780, height: 620)
    /// No `outerCornerRadius` token — the window's outer corner is AppKit's
    /// own native mask (see WindowConfiguringView), not a hardcoded clip.

    static let sidebarWidth: CGFloat = 210
    /// Band across the top of the window where AppKit draws the real traffic
    /// lights; the sidebar's first pane starts below it.
    static let headerHeight: CGFloat = 52
    static let headerButtonHeight: CGFloat = 28
    static let headerButtonFont = Font.system(size: 12, weight: .medium)
    /// The inset card that holds the selected pane.
    static let detailCornerRadius: CGFloat = 16
    /// Page content's inset from the detail card's side edges; the header lines up with it.
    static let contentHorizontalPadding: CGFloat = 20

    /// Light-mode values match the exact resolved alpha AppKit's own
    /// `NSColor.labelColor`/`.secondaryLabelColor` use (`black @ 0.85`/`0.50`),
    /// so text reads with the same contrast as every other native app.
    static let textPrimary = adaptiveColor(
        dark: NSColor(red: 0xEE / 255, green: 0xEE / 255, blue: 0xEE / 255, alpha: 1),
        light: NSColor(white: 0, alpha: 0.85)
    )
    static let textSecondary = adaptiveColor(
        dark: NSColor(red: 0xBF / 255, green: 0xBF / 255, blue: 0xBF / 255, alpha: 1),
        light: NSColor(white: 0, alpha: 0.50)
    )
    static let textTertiary = adaptiveColor(
        dark: NSColor(red: 0x99 / 255, green: 0x99 / 255, blue: 0x99 / 255, alpha: 1),
        light: NSColor(white: 0, alpha: 0.4)
    )

    static let rowHeight: CGFloat = 46
    static let rowRadius: CGFloat = 12
    /// Primary at 5% / 7%: a faint grouped-card fill and hairline that read in both appearances.
    static let rowColor = adaptiveColor(
        dark: NSColor(white: 1, alpha: 0.05),
        light: NSColor(white: 0, alpha: 0.05)
    )
    static let rowBorder = adaptiveColor(
        dark: NSColor(white: 1, alpha: 0.07),
        light: NSColor(white: 0, alpha: 0.07)
    )
    static let rowBorderWidth: CGFloat = 1
    static let rowFont = Font.system(size: 13, weight: .regular)
    static let rowSpacing: CGFloat = 18
    static let rowHorizontalInset: CGFloat = 16
    /// Shared cap on a row's subtitle width — keeps a longer explanatory
    /// line from stretching toward the trailing control.
    static let rowSubtitleMaxWidth: CGFloat = 360
    /// Two-line slider rows size to their content instead of `rowHeight`;
    /// this keeps their total height visually in step with single-line rows
    /// in the same group.
    static let sliderRowVerticalPadding: CGFloat = 12

    /// Neutral (non-accent, non-destructive) button fill — the resting state
    /// of `HoldToConfirmButton`, which only turns red as it fills.
    static let neutralButtonFill = adaptiveColor(
        dark: NSColor(white: 1, alpha: 0.14),
        light: NSColor(white: 0, alpha: 0.10)
    )
    static let destructiveFill = Color(red: 0xE0 / 255, green: 0x3B / 255, blue: 0x2F / 255)

    /// Centered empty/locked-state block (icon, caption, action button).
    static let emptyStateIconSize: CGFloat = 40
    static let emptyStateSpacing: CGFloat = 14
    static let emptyStateMinHeight: CGFloat = 380
    /// Crossfade between the locked and unlocked states of gated pages.
    static let stateTransitionAnimation = Animation.easeInOut(duration: 0.28)

    /// Option pickers: a row of equal-width tiles, each a preview above its label.
    static let optionCardVerticalPadding: CGFloat = 14
    static let optionPreviewHeight: CGFloat = 80
    static let unlockAnimationOptionPreviewHeight: CGFloat = 110
    static let optionPreviewCornerRadius: CGFloat = 12
    static let optionLabelFont = Font.callout.weight(.medium)
    static let optionItemSpacing: CGFloat = 12
    static let sectionTitleFont = Font.callout.weight(.semibold)
    static let sectionTitleHorizontalInset: CGFloat = 12
    static let sectionTitleVerticalPadding: CGFloat = 8

    // MARK: - Capture-quality tick strip (Your Face)
    //
    // One tick per stored sample, colored by `FaceSample.QualityTier`.
    // Fixed literals rather than `adaptiveColor` — semantic red/amber/green
    // that reads correctly against both dark and light content panels.

    static let qualityPoorColor = Color(red: 0xFF / 255, green: 0x54 / 255, blue: 0x54 / 255)
    static let qualityFairColor = Color(red: 0xFF / 255, green: 0xBE / 255, blue: 0x54 / 255)
    static let qualityGoodColor = Color(red: 0x85 / 255, green: 0xFF / 255, blue: 0x77 / 255)
    /// Samples with no recorded score — enrollments predating per-sample
    /// quality. Deliberately neutral: unrated is not the same as poor.
    static let qualityUnratedColor = adaptiveColor(
        dark: NSColor(white: 1, alpha: 0.22),
        light: NSColor(white: 0, alpha: 0.20)
    )

    static let qualityTickWidth: CGFloat = 3.5
    static let qualityTickSpacing: CGFloat = 5.5
    static let qualityTickHeight: CGFloat = 26
    /// Caps the strip so an identity with an unusual number of samples
    /// compresses its ticks rather than running off the card.
    static let qualityStripMaxWidth: CGFloat = 300

    /// Resolves live against the current system appearance rather than a
    /// value fixed at evaluation time.
    private static func adaptiveColor(dark: NSColor, light: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
