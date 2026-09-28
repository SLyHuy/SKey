// Draws the SKey app icon and writes App/Assets.xcassets/AppIcon.appiconset.
// Run from the repo root:  swift scripts/make-icon.swift [preview.png]
//
// Design: a white Mac keycap on a deep blue squircle. The key carries a bold rounded "S"
// with a coral acute accent: the S of SKey, a Vietnamese tone mark, and the very key that
// types the acute tone in Telex.
import AppKit

let output = URL(fileURLWithPath: "App/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// Continuous-corner rounded rectangle (superellipse corners), like macOS icons.
func squircle(_ r: CGRect, radius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    let k: CGFloat = 1.28  // how far the curve starts before the corner, relative to radius
    let c = min(radius * k, min(r.width, r.height) / 2)
    path.move(to: CGPoint(x: r.minX + c, y: r.minY))
    path.addLine(to: CGPoint(x: r.maxX - c, y: r.minY))
    path.addCurve(to: CGPoint(x: r.maxX, y: r.minY + c),
                  control1: CGPoint(x: r.maxX - c * 0.36, y: r.minY), control2: CGPoint(x: r.maxX, y: r.minY + c * 0.36))
    path.addLine(to: CGPoint(x: r.maxX, y: r.maxY - c))
    path.addCurve(to: CGPoint(x: r.maxX - c, y: r.maxY),
                  control1: CGPoint(x: r.maxX, y: r.maxY - c * 0.36), control2: CGPoint(x: r.maxX - c * 0.36, y: r.maxY))
    path.addLine(to: CGPoint(x: r.minX + c, y: r.maxY))
    path.addCurve(to: CGPoint(x: r.minX, y: r.maxY - c),
                  control1: CGPoint(x: r.minX + c * 0.36, y: r.maxY), control2: CGPoint(x: r.minX, y: r.maxY - c * 0.36))
    path.addLine(to: CGPoint(x: r.minX, y: r.minY + c))
    path.addCurve(to: CGPoint(x: r.minX + c, y: r.minY),
                  control1: CGPoint(x: r.minX, y: r.minY + c * 0.36), control2: CGPoint(x: r.minX + c * 0.36, y: r.minY))
    path.closeSubpath()
    return path
}

func linearGradient(_ ctx: CGContext, _ path: CGPath, _ colors: [CGColor], from: CGPoint, to: CGPoint) {
    ctx.saveGState()
    ctx.addPath(path)
    ctx.clip()
    let g = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: nil)!
    ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

func drawIcon(in ctx: CGContext, size s: CGFloat) {
    let u = s / 1024  // design units on the 1024 macOS icon grid
    func R(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect { CGRect(x: x * u, y: y * u, width: w * u, height: h * u) }
    func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * u, y: y * u) }

    // 1. Body: deep blue squircle with a soft drop shadow.
    let body = squircle(R(100, 100, 824, 824), radius: 185 * u)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -12 * u), blur: 30 * u, color: color(0x000000, 0.30))
    ctx.addPath(body)
    ctx.setFillColor(color(0x2440B8))
    ctx.fillPath()
    ctx.restoreGState()
    linearGradient(ctx, body, [color(0x4F86FF), color(0x2B45C9), color(0x1B2A8A)], from: P(512, 924), to: P(512, 100))
    // Gentle light from the top.
    ctx.saveGState()
    ctx.addPath(body)
    ctx.clip()
    let glow = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                          colors: [color(0xFFFFFF, 0.22), color(0xFFFFFF, 0)] as CFArray, locations: nil)!
    ctx.drawRadialGradient(glow, startCenter: P(512, 900), startRadius: 0, endCenter: P(512, 900), endRadius: 560 * u, options: [])
    ctx.restoreGState()

    // 2. Keycap: shadow, skirt (the key's sides), then the slightly dished top face.
    let skirt = squircle(R(222, 206, 580, 590), radius: 118 * u)
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -26 * u), blur: 44 * u, color: color(0x0B1450, 0.55))
    ctx.addPath(skirt)
    ctx.setFillColor(color(0xC3CCE4))
    ctx.fillPath()
    ctx.restoreGState()
    linearGradient(ctx, skirt, [color(0xE4E9F6), color(0xB3BEDC)], from: P(512, 796), to: P(512, 206))

    let top = squircle(R(262, 290, 500, 480), radius: 92 * u)
    linearGradient(ctx, top, [color(0xFFFFFF), color(0xEEF2FB)], from: P(512, 770), to: P(512, 290))
    ctx.saveGState()  // thin highlight rim on the top face
    ctx.addPath(top)
    ctx.setStrokeColor(color(0xFFFFFF, 0.9))
    ctx.setLineWidth(3 * u)
    ctx.strokePath()
    ctx.restoreGState()

    // 3. Legend: bold rounded "S" in ink, coral acute accent (dấu sắc).
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
    let base = NSFont.systemFont(ofSize: 320 * u, weight: .heavy)
    let font = base.fontDescriptor.withDesign(.rounded).flatMap { NSFont(descriptor: $0, size: 320 * u) } ?? base
    let s = NSAttributedString(string: "S", attributes: [.font: font, .foregroundColor: NSColor(cgColor: color(0x1C2660))!])
    let width = s.size().width
    let centerX: CGFloat = 500 * u
    let baseline = 500 * u - font.capHeight / 2 - 24 * u
    s.draw(at: NSPoint(x: centerX - width / 2, y: baseline + font.descender))
    NSGraphicsContext.restoreGraphicsState()

    let accent = CGMutablePath()
    accent.move(to: P(566, 636))
    accent.addLine(to: P(612, 690))
    ctx.saveGState()
    ctx.addPath(accent)
    ctx.setLineCap(.round)
    ctx.setLineWidth(40 * u)
    ctx.setStrokeColor(color(0xFF5A4F))
    ctx.strokePath()
    ctx.restoreGState()
}

func png(pixels: Int) -> Data {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    drawIcon(in: ctx, size: CGFloat(pixels))
    return NSBitmapImageRep(cgImage: ctx.makeImage()!).representation(using: .png, properties: [:])!
}

// Optional: a preview sheet (1024 plus the small sizes as macOS shows them).
if CommandLine.arguments.count > 1 {
    let sizes: [CGFloat] = [512, 128, 64, 32, 16]
    let sheet = CGContext(data: nil, width: 1000, height: 560, bitsPerComponent: 8, bytesPerRow: 0,
                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    for (i, bg) in [color(0xF2F2F2), color(0x1E1E1E)].enumerated() {
        sheet.setFillColor(bg)
        sheet.fill(CGRect(x: CGFloat(i) * 500, y: 0, width: 500, height: 560))
        var x = CGFloat(i) * 500 + 20
        for size in sizes {
            let img = NSImage(data: png(pixels: Int(size * 2)))!.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let shown = size == 512 ? 300 : size
            let y: CGFloat = size == 512 ? 230 : 110
            sheet.draw(img, in: CGRect(x: x, y: y, width: shown, height: shown))
            x += size == 512 ? 0 : shown + 18
            if size == 512 { x = CGFloat(i) * 500 + 20 }
        }
    }
    let data = NSBitmapImageRep(cgImage: sheet.makeImage()!).representation(using: .png, properties: [:])!
    try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
    print("Preview written to \(CommandLine.arguments[1])")
    exit(0)
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
