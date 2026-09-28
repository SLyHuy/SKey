// Draws the SKey app icon and writes App/Assets.xcassets/AppIcon.appiconset.
// Run from the repo root:  swift scripts/make-icon.swift
import AppKit

let output = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

func drawIcon(in ctx: CGContext, size s: CGFloat) {
    let u = s / 1024  // design units: 1024 × 1024 canvas, macOS icon grid
    let body = CGRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u)
    let bodyPath = CGPath(roundedRect: body, cornerWidth: 185 * u, cornerHeight: 185 * u, transform: nil)

    // Soft drop shadow, then the blue → indigo body.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -10 * u), blur: 28 * u,
                  color: CGColor(gray: 0, alpha: 0.28))
    ctx.addPath(bodyPath)
    ctx.setFillColor(CGColor(red: 0.20, green: 0.33, blue: 0.86, alpha: 1))
    ctx.fillPath()
    ctx.restoreGState()

    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: [
        CGColor(red: 0.33, green: 0.55, blue: 1.00, alpha: 1),
        CGColor(red: 0.20, green: 0.27, blue: 0.82, alpha: 1),
    ] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.maxY), end: CGPoint(x: 0, y: body.minY), options: [])
    ctx.restoreGState()

    // The input badge, same proportions as the menu bar icon (22 × 16, 4 pt corners).
    let badge = CGRect(x: 512 * u - 260 * u, y: 446 * u, width: 520 * u, height: 378 * u)
    ctx.addPath(CGPath(roundedRect: badge, cornerWidth: 94 * u, cornerHeight: 94 * u, transform: nil))
    ctx.setFillColor(.white)
    ctx.fillPath()

    let ns = NSGraphicsContext(cgContext: ctx, flipped: false)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ns

    let badgeFont = NSFont.systemFont(ofSize: 272 * u, weight: .bold)
    let vi = NSAttributedString(string: "VI", attributes: [
        .font: badgeFont,
        .foregroundColor: NSColor(red: 0.24, green: 0.36, blue: 0.90, alpha: 1),
        .kern: 6 * u,
    ])
    let viWidth = vi.size().width - 6 * u
    let viBaseline = badge.midY - badgeFont.capHeight / 2
    vi.draw(at: NSPoint(x: badge.midX - viWidth / 2, y: viBaseline + badgeFont.descender))

    // "</>" underneath: made for code.
    let codeFont = NSFont.monospacedSystemFont(ofSize: 150 * u, weight: .semibold)
    let code = NSAttributedString(string: "</>", attributes: [
        .font: codeFont,
        .foregroundColor: NSColor(white: 1, alpha: 0.85),
    ])
    let codeWidth = code.size().width
    let codeBaseline = 262 * u - codeFont.capHeight / 2
    code.draw(at: NSPoint(x: 512 * u - codeWidth / 2, y: codeBaseline + codeFont.descender))

    NSGraphicsContext.restoreGraphicsState()
}

func png(pixels: Int) -> Data {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawIcon(in: ctx, size: CGFloat(pixels))
    let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
    return rep.representation(using: .png, properties: [:])!
}

let entries: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2), (256, 1), (256, 2), (512, 1), (512, 2),
]
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
var images: [[String: String]] = []
for e in entries {
    let name = "icon_\(e.points)x\(e.points)@\(e.scale)x.png"
    try png(pixels: e.points * e.scale).write(to: output.appendingPathComponent(name))
    images.append(["idiom": "mac", "size": "\(e.points)x\(e.points)", "scale": "\(e.scale)x", "filename": name])
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))

let catalog = output.deletingLastPathComponent().appendingPathComponent("Contents.json")
try #"{ "info" : { "author" : "xcode", "version" : 1 } }"#.data(using: .utf8)!.write(to: catalog)
print("Wrote \(entries.count) icons to \(output.path)")
