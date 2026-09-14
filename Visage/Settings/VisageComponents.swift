//
//  VisageComponents.swift
//  Visage
//
//  The Visage mark and the shared building blocks of its panes: icon tiles,
//  cards, status rows and badges.
//

import SwiftUI

// MARK: - Mark

/// Visage's own mark: scan brackets around an open eye, on a 100-unit grid.
/// The app icon and the menu bar icon draw the same geometry.
struct VisageMarkView: View {
    var lineWidth: CGFloat = 3

    var body: some View {
        GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                VisageBrackets()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                VisageEye()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                Circle()
                    .frame(width: side * 0.16, height: side * 0.16)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

private func markPoint(_ rect: CGRect, _ x: CGFloat, _ y: CGFloat) -> CGPoint {
    let scale = min(rect.width, rect.height) / 100
    return CGPoint(x: rect.midX + (x - 50) * scale, y: rect.midY + (y - 50) * scale)
}

struct VisageBrackets: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { markPoint(rect, x, y) }
        var path = Path()
        path.move(to: p(8, 32)); path.addLine(to: p(8, 20)); path.addQuadCurve(to: p(20, 8), control: p(8, 8)); path.addLine(to: p(32, 8))
        path.move(to: p(68, 8)); path.addLine(to: p(80, 8)); path.addQuadCurve(to: p(92, 20), control: p(92, 8)); path.addLine(to: p(92, 32))
        path.move(to: p(92, 68)); path.addLine(to: p(92, 80)); path.addQuadCurve(to: p(80, 92), control: p(92, 92)); path.addLine(to: p(68, 92))
        path.move(to: p(32, 92)); path.addLine(to: p(20, 92)); path.addQuadCurve(to: p(8, 80), control: p(8, 92)); path.addLine(to: p(8, 68))
        return path
    }
}

struct VisageEye: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { markPoint(rect, x, y) }
        var path = Path()
        path.move(to: p(24, 50))
        path.addQuadCurve(to: p(76, 50), control: p(50, 26))
        path.addQuadCurve(to: p(24, 50), control: p(50, 74))
        path.closeSubpath()
        return path
    }
}

/// The app mark: the Visage glyph on a dark rounded square, matching the app icon.
struct AppGlyph: View {
    let size: CGFloat

    var body: some View {
        VisageMarkView(lineWidth: max(1.5, size * 0.055))
            .foregroundStyle(.white)
            .padding(size * 0.2)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [Color(white: 0.24), Color(white: 0.08)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            )
            .shadow(color: .black.opacity(0.18), radius: size * 0.08, y: size * 0.04)
    }
}

// MARK: - Building blocks

/// A white SF Symbol on a colored rounded square — the sidebar and pane header icon.
struct IconTile: View {
    let symbol: String
    let color: Color
    var size: CGFloat = 26

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: size * 0.27, style: .continuous))
    }
}

struct Card<Content: View>: View {
    let padding: CGFloat
    let content: Content

    init(padding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SettingsMetrics.rowColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(SettingsMetrics.rowBorder))
    }
}

struct Badge {
    let text: String
    let color: Color

    init(_ text: String, _ color: Color) {
        self.text = text
        self.color = color
    }
}

/// Icon tile, title and detail, with an optional trailing badge.
struct StatusRow: View {
    let symbol: String
    let color: Color
    let title: String
    let detail: String
    var badge: Badge?

    var body: some View {
        HStack(spacing: 14) {
            IconTile(symbol: symbol, color: color, size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(SettingsMetrics.textPrimary)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(SettingsMetrics.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            if let badge {
                Text(badge.text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(badge.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(badge.color.opacity(0.14), in: Capsule())
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
    }
}

/// Divider inset to line up with a `StatusRow`'s text.
struct RowDivider: View {
    var body: some View {
        Divider().padding(.leading, 62)
    }
}
