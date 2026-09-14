// Renders SF Symbols as 64px black PNGs for the website's app preview.
// Usage: swift scripts/render-symbols.swift website/assets/symbols moon.fill space …
import AppKit

let outputDirectory = CommandLine.arguments[1]
for name in CommandLine.arguments.dropFirst(2) {
    guard let symbol = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: 40, weight: .regular)) else {
        print("missing symbol: \(name)")
        continue
    }
    let pixels = 64
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = min(52 / symbol.size.width, 52 / symbol.size.height)
    let size = NSSize(width: symbol.size.width * scale, height: symbol.size.height * scale)
    let tinted = NSImage(size: symbol.size, flipped: false) { rect in
        symbol.draw(in: rect)
        NSColor.black.set()
        rect.fill(using: .sourceAtop)
        return true
    }
    tinted.draw(in: NSRect(x: (64 - size.width) / 2, y: (64 - size.height) / 2, width: size.width, height: size.height))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(outputDirectory)/\(name).png"))
}
