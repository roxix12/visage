// Renders the Visage mark (the face glyph from the unlock animation) into the app icon set
// and a 1024px master for the website. Usage: swift scripts/make-icon.swift
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

/// The mark on a 100-unit grid: scan brackets around a face (eyes, nose, smile).
func markPath(size: CGFloat, inset: CGFloat) -> CGPath {
    let unit = (size - inset * 2) / 100
    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: inset + x * unit, y: size - (inset + y * unit)) }
    let path = CGMutablePath()
    // Corner brackets.
    path.move(to: p(8, 32)); path.addLine(to: p(8, 20)); path.addQuadCurve(to: p(20, 8), control: p(8, 8)); path.addLine(to: p(32, 8))
    path.move(to: p(68, 8)); path.addLine(to: p(80, 8)); path.addQuadCurve(to: p(92, 20), control: p(92, 8)); path.addLine(to: p(92, 32))
    path.move(to: p(92, 68)); path.addLine(to: p(92, 80)); path.addQuadCurve(to: p(80, 92), control: p(92, 92)); path.addLine(to: p(68, 92))
    path.move(to: p(32, 92)); path.addLine(to: p(20, 92)); path.addQuadCurve(to: p(8, 80), control: p(8, 92)); path.addLine(to: p(8, 68))
    // Eyes.
    path.move(to: p(36, 38)); path.addLine(to: p(36, 48))
    path.move(to: p(64, 38)); path.addLine(to: p(64, 48))
    // Nose.
    path.move(to: p(53, 38)); path.addLine(to: p(47, 57)); path.addLine(to: p(55, 57))
    // Smile.
    path.move(to: p(36, 66)); path.addQuadCurve(to: p(64, 66), control: p(50, 76))
    return path
}

func render(_ pixels: Int) -> Data {
    let size = CGFloat(pixels)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext

    // Graphite squircle, inset like every other macOS icon.
    let inset = size * 0.1
    let body = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let shape = NSBezierPath(roundedRect: body, xRadius: body.width * 0.225, yRadius: body.width * 0.225)
    NSGradient(starting: NSColor(srgbRed: 0.17, green: 0.19, blue: 0.23, alpha: 1),
               ending: NSColor(srgbRed: 0.04, green: 0.05, blue: 0.07, alpha: 1))!.draw(in: shape, angle: -90)
    NSColor(white: 1, alpha: 0.08).setStroke(); shape.lineWidth = max(1, size * 0.004); shape.stroke()

    // The mark, in the app's accent blue.
    let markInset = inset + body.width * 0.2
    context.setStrokeColor(NSColor(srgbRed: 0x34 / 255, green: 0x99 / 255, blue: 1, alpha: 1).cgColor)
    context.setLineWidth(max(1, size * 0.045))
    context.setLineCap(.round)
    context.setLineJoin(.round)
    context.addPath(markPath(size: size, inset: markInset))
    context.strokePath()

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for size in [16, 32, 128, 256, 512] {
    try render(size).write(to: iconset.appendingPathComponent("icon_\(size)x\(size).png"))
    try render(size * 2).write(to: iconset.appendingPathComponent("icon_\(size)x\(size)@2x.png"))
}
// The asset catalog takes the same files; the website master is the largest one.
let appiconset = root.appendingPathComponent("Visage/Assets.xcassets/AppIcon.appiconset")
for file in try FileManager.default.contentsOfDirectory(at: iconset, includingPropertiesForKeys: nil) where file.pathExtension == "png" {
    try? FileManager.default.removeItem(at: appiconset.appendingPathComponent(file.lastPathComponent))
    try FileManager.default.copyItem(at: file, to: appiconset.appendingPathComponent(file.lastPathComponent))
}
try render(1024).write(to: root.appendingPathComponent("website/assets/visage-icon.png"))
print("icons rendered")
