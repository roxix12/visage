//
//  SettingsTab.swift
//  Visage
//
//  The sidebar's panes, in order and grouped. Debug-only Face Lab — the remaining live test
//  harness, kept for ongoing tuning — is appended only once revealed.
//

import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case overview
    case general
    case yourFace
    case password
    case camera
    case recognition
    case privacy
    case community
    case about
    case debugFaceLab

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: return "Overview"
        case .general: return "General"
        case .yourFace: return "Your Face"
        case .password: return "Password"
        case .camera: return "Camera"
        case .recognition: return "Recognition"
        case .privacy: return "Privacy"
        case .community: return "Community"
        case .about: return "About"
        case .debugFaceLab: return "Face Lab"
        }
    }

    var symbol: String {
        switch self {
        case .overview: return "square.grid.2x2.fill"
        case .general: return "gearshape.fill"
        case .yourFace: return "viewfinder"
        case .password: return "lock.fill"
        case .camera: return "video.fill"
        case .recognition: return "sparkles"
        case .privacy: return "hand.raised.fill"
        case .community: return "bubble.left.and.bubble.right.fill"
        case .about: return "info"
        case .debugFaceLab: return "flask.fill"
        }
    }

    /// Fill of the pane's icon tile in the sidebar and header.
    var color: Color {
        switch self {
        case .overview: return .teal
        case .general, .about: return .gray
        case .yourFace: return .blue
        case .password: return Color(white: 0.22)
        case .camera: return .green
        case .recognition: return .purple
        case .privacy: return .indigo
        // Discord's blurple, so the pane reads as the Discord one.
        case .community: return Color(red: 0x58 / 255, green: 0x65 / 255, blue: 0xF2 / 255)
        case .debugFaceLab: return .orange
        }
    }

    /// Sidebar sections in order, minus `.debugFaceLab` unless it's been
    /// unlocked this launch — see `AppEnvironment.isDebugSectionRevealed`.
    static func sections(includingDebug: Bool) -> [(title: String?, tabs: [SettingsTab])] {
        [
            (nil, [.overview, .general]),
            ("Authentication", [.yourFace, .password, .camera, .recognition]),
            ("Visage", [.privacy, .community, .about] + (includingDebug ? [.debugFaceLab] : [])),
        ]
    }
}
