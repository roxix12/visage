//
//  VisageComponents.swift
//  Visage
//
//  The Visage mark and the shared building blocks of its panes: icon tiles,
//  cards, status rows and badges.
//

import SwiftUI

// MARK: - Mark

/// Visage's mark: scan brackets around a face, on a 100-unit grid.
/// The app icon (scripts/make-icon.swift) and the menu bar icon draw the same geometry.
struct VisageMarkView: View {
    var lineWidth: CGFloat = 3
    /// The mark draws itself in and sweeps a scan line, echoing the unlock animation.
    /// Set false (or turn on Reduce Motion) for a still mark.
    var animated: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// One full loop: draw in, hold, scan, hold.
    private static let cycle: Double = 6.4

    var body: some View {
        if animated && !reduceMotion {
            TimelineView(.animation) { context in
                mark(at: context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.cycle))
            }
        } else {
            // Past the scan, so the glyph is complete and the line is gone.
            mark(at: Self.cycle * 0.9)
        }
    }

    private func mark(at time: Double) -> some View {
        let brackets = eased(time, start: 0, duration: 0.7)
        let eyes = eased(time, start: 0.45, duration: 0.55)
        let nose = eased(time, start: 0.7, duration: 0.55)
        let smile = eased(time, start: 0.9, duration: 0.6)
        let scan = eased(time, start: 1.95, duration: 1.4)
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        return GeometryReader { geometry in
            let side = min(geometry.size.width, geometry.size.height)
            ZStack {
                VisageBrackets().trim(from: 0, to: brackets).stroke(style: style)
                VisageEyes().trim(from: 0, to: eyes).stroke(style: style)
                VisageNose().trim(from: 0, to: nose).stroke(style: style)
                VisageSmile().trim(from: 0, to: smile).stroke(style: style)
                Capsule()
                    .frame(width: side * 0.66, height: max(1, lineWidth * 0.6))
                    .offset(y: side * (-0.2 + 0.4 * scan))
                    .opacity(scanOpacity(scan))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// Smoothstep between `start` and `start + duration`, clamped either side.
    private func eased(_ time: Double, start: Double, duration: Double) -> CGFloat {
        let t = min(max((time - start) / duration, 0), 1)
        return CGFloat(t * t * (3 - 2 * t))
    }

    /// The line fades in, sweeps, and fades out again.
    private func scanOpacity(_ progress: CGFloat) -> Double {
        guard progress > 0, progress < 1 else { return 0 }
        if progress < 0.15 { return Double(progress / 0.15) }
        if progress > 0.85 { return Double((1 - progress) / 0.15) }
        return 1
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

struct VisageEyes: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { markPoint(rect, x, y) }
        var path = Path()
        path.move(to: p(36, 38)); path.addLine(to: p(36, 48))
        path.move(to: p(64, 38)); path.addLine(to: p(64, 48))
        return path
    }
}

struct VisageNose: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { markPoint(rect, x, y) }
        var path = Path()
        path.move(to: p(53, 38)); path.addLine(to: p(47, 57)); path.addLine(to: p(55, 57))
        return path
    }
}

struct VisageSmile: Shape {
    func path(in rect: CGRect) -> Path {
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { markPoint(rect, x, y) }
        var path = Path()
        path.move(to: p(36, 66)); path.addQuadCurve(to: p(64, 66), control: p(50, 76))
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
